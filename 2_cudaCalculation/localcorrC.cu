#include <stdio.h>
#include <string.h>
#include "cuda/common/book.h"

#define FRAMES	27717	// Number of Frames
#define DELTAT	10	//4// In centiseconds so time is integer
#define TAURES	2	//5// will be multplied by DELTAT
#define TRES	1	// will be multplied by DELTAT
#define TAUMAX	40	//100// will be multplied by DELTAT
#define TAUS	int(2*TAUMAX+1)	// Number of Taus
#define FRAMESHALFWINDOW	10	//25// Number of Frames, these data are averaged out
#define RESULT_TS	int(FRAMES/TRES)
#define RESULT_TAUS	int(2*int(TAUMAX/TAURES)+1)


__global__ void corr( float *aX, float *aY, float *bX, float *bY, float *c) {
    int f = blockIdx.x;
    int tau = threadIdx.x;

    if( (f < FRAMES-TAUMAX) && (f >= TAUMAX) ){
	    int f2 = f + tau - TAUMAX;
    	    c[f*TAUS+tau] = aX[f] * bX[f2] + aY[f] * bY[f2];	//GOOD
    	    //c[f*TAUS+tau] = bY[f2];	//TEST
    } else {
	    c[f*TAUS+tau]=0;
    }
}

__global__ void avrCorr( float *c, float *avrC) {
    int t = blockIdx.x;
    int tauR = threadIdx.x;
    int f = t*TRES;
    
    if( (f < FRAMES-TAUMAX) && (f >= TAUMAX) ){
	int Num=0;
	float Sum=0;
	int tau = tauR*TAURES;

	for(int f1=f-FRAMESHALFWINDOW; f1<f+FRAMESHALFWINDOW; f1++){
	    if(c[f1*TAUS+tau] != 0){
		Sum += c[f1*TAUS+tau];
		Num ++;
	    }
	}
	if(Num>0){
	    avrC[t*RESULT_TAUS+tauR] = Sum/(1.0*Num);
	} else {
	    avrC[t*RESULT_TAUS+tauR] = 0;
	}
	//    avrC[t*RESULT_TAUS+tauR] = c[f*TAUS+tau]; //TEST
    } else {
	    avrC[t*RESULT_TAUS+tauR] = 0;
    }
}	

__global__ void getmaxCorr( float *avrC, float *maxC, float *maxTau) {
    int t = blockIdx.x;
    int f = t*TRES;

    if( (f < FRAMES-TAUMAX) && (f >= TAUMAX) ){
	for (int tauR=0; tauR<RESULT_TAUS; tauR++) {
	    int tau = tauR * TAURES;
    
	    if( avrC[t*RESULT_TAUS+tauR] > maxC[t]){
		maxC[t] = avrC[t*RESULT_TAUS+tauR];
		maxTau[t] = tau;
	    }
	}
    } else {
		maxC[t] = 0;
		maxTau[t] = 0;
    }
}

int main(int argc, char **argv) {
    int t1;
    int time[FRAMES];
    float vix1, viy1, vjx1, vjy1;
    float vix[FRAMES], viy[FRAMES], vjx[FRAMES], vjy[FRAMES];
    float avrC[RESULT_TS*RESULT_TAUS];
    float maxC[RESULT_TS];
    float maxTau[RESULT_TS];
    //float dev_Cij[FRAMES*TAUS];
    float *dev_vix, *dev_viy, *dev_vjx, *dev_vjy, *dev_Cij, *dev_avrC, *dev_maxC, *dev_maxTau;
    
    // Get input parameters to read and to write
    if (argc < 4) {
	    fprintf(stderr, "Give 2 arguments for input and 2 output file names!\n");
	    exit(1);
    }
    // Input file
    FILE *ifp = fopen(argv[1], "r");
    if (ifp == NULL) {
        fprintf(stderr, "Can't open input file %s!\n", argv[1]);
        exit(1);
    }
    // Output file
    FILE *ofp = fopen(argv[2], "w");
    if (ofp == NULL) {
	fprintf(stderr, "Can't open output file %s!\n", argv[2]);
	exit(1);
    }

    // Output file2 for max Cor and Tau
    FILE *ofp2 = fopen(argv[3], "w");
    if (ofp2 == NULL) {
	fprintf(stderr, "Can't open output file %s!\n", argv[3]);
	exit(1);
    }
    //// Read data from file
    int i=0;
    float vi, vj;
    while (fscanf(ifp, "%d %f %f %f %f", &t1, &vix1, &viy1, &vjx1, &vjy1) != EOF) {
	//fprintf(ofp, "%d %.4f\n", t1, vix1);	//TEST
	time[i]=t1;
	vi=sqrt(vix1*vix1+viy1*viy1);
	if(vi>0){
	    vix[i]=vix1/vi;
	    viy[i]=viy1/vi;
	} else {
	    vix[i]=0;
	    viy[i]=0;
	}
	vj=sqrt(vjx1*vjx1+vjy1*vjy1);
	if(vj>0){
	    vjx[i]=vjx1/vj;
	    vjy[i]=vjy1/vj;
	} else {
	    vjx[i]=0;
	    vjy[i]=0;
	}
	i++;
    }
    //// Close input file
    fclose(ifp);
    
    //// Initialize output
    for (int t=0; t<RESULT_TS; t++) {
    	maxC[t]=0;
    	maxTau[t]=0;
	for (int tau=0; tau<RESULT_TAUS; tau++) {
    	    avrC[t*RESULT_TAUS+tau]=0;
	}
    }

    // allocate the memory on the GPU
    HANDLE_ERROR( cudaMalloc( (void**)&dev_vix, FRAMES * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_viy, FRAMES * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_vjx, FRAMES * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_vjy, FRAMES * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_Cij, FRAMES*TAUS * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_avrC, RESULT_TS*RESULT_TAUS * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_maxC, RESULT_TS * sizeof(float) ) );
    HANDLE_ERROR( cudaMalloc( (void**)&dev_maxTau, RESULT_TS * sizeof(float) ) );

    // copy the v arrays to the GPU
    HANDLE_ERROR( cudaMemcpy( dev_vix, vix, FRAMES * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_viy, viy, FRAMES * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_vjx, vjx, FRAMES * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_vjy, vjy, FRAMES * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_maxC, maxC, RESULT_TS * sizeof(float), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( dev_maxTau, maxTau, RESULT_TS * sizeof(float), cudaMemcpyHostToDevice ) );

    corr<<<FRAMES,TAUS>>>(dev_vix, dev_viy, dev_vjx, dev_vjy, dev_Cij);
    avrCorr<<<RESULT_TS,RESULT_TAUS>>>(dev_Cij, dev_avrC);
    getmaxCorr<<<RESULT_TS,1>>>(dev_avrC, dev_maxC, dev_maxTau);

    //// copy the array 'c' back from the GPU to the CPU
    HANDLE_ERROR( cudaMemcpy( avrC, dev_avrC, RESULT_TS*RESULT_TAUS * sizeof(float), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( maxC, dev_maxC, RESULT_TS * sizeof(float), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( maxTau, dev_maxTau, RESULT_TS * sizeof(float), cudaMemcpyDeviceToHost ) );
    

    fprintf(ofp, "#%s\n", argv[1] );		fprintf(ofp2, "#%s\n", argv[1] );		
    fprintf(ofp, "#FRAMES: %d\n", FRAMES );     fprintf(ofp2, "#FRAMES: %d\n", FRAMES );
    fprintf(ofp, "#DELTAT: %d\n", DELTAT );     fprintf(ofp2, "#DELTAT: %d\n", DELTAT );
    fprintf(ofp, "#TAURES: %d\n", TAURES );     fprintf(ofp2, "#TAURES: %d\n", TAURES );
    fprintf(ofp, "#TRES: %d\n",   TRES );       fprintf(ofp2, "#TRES: %d\n",   TRES );
    fprintf(ofp, "#TAUMAX: %d\n", TAUMAX );     fprintf(ofp2, "#TAUMAX: %d\n", TAUMAX );
    fprintf(ofp, "#time\t");		        fprintf(ofp2, "#time\tmaxCor\tmaxTau\n");
    for (int tauR=0; tauR<RESULT_TAUS; tauR++) {
	int tau = tauR * TAURES;
    	fprintf(ofp, "%d\t", (tau-TAUMAX)*DELTAT);
    }
    fprintf(ofp, "\n");
    // display the results
    int f=0;
    for (int t=0; t<RESULT_TS; t++) {
	f = t*TRES;
    	fprintf(ofp, "%d\t", time[f]);
	for (int tauR=0; tauR<RESULT_TAUS; tauR++) {
    	    fprintf(ofp, "%.4f\t", avrC[t*RESULT_TAUS+tauR] );
	}
	fprintf(ofp, "\n");
    	fprintf(ofp2, "%d\t%.4f\t%.4f\n", time[f], maxC[t], (maxTau[t]-TAUMAX)*DELTAT );
    }


    // free the memory allocated on the GPU
    HANDLE_ERROR( cudaFree( dev_vix ) );
    HANDLE_ERROR( cudaFree( dev_viy ) );
    HANDLE_ERROR( cudaFree( dev_vjx ) );
    HANDLE_ERROR( cudaFree( dev_vjy ) );
    HANDLE_ERROR( cudaFree( dev_Cij ) );
    HANDLE_ERROR( cudaFree( dev_avrC ) );
    HANDLE_ERROR( cudaFree( dev_maxC ) );
    HANDLE_ERROR( cudaFree( dev_maxTau ) );

    //// Close output file
    fclose(ofp);
    fclose(ofp2);

    return 0;
}