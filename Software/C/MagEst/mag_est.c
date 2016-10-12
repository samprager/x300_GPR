#include <math.h>
#include <stdio.h>
/*********************************************************************
*
*
* Name: mag_est.c
*
* Synopsis:
*
*   Demonstrates and tests the "Alpha * Min + Beta * Max" magnitude
*   estimation algorithm.
*
* Description:
*
*   This program demonstrates the "Alpha, Beta" algorithm for
*   estimating the magnitude of a complex number.  Compared to
*   calculating the magnitude directly using sqrt(I^2 + Q^2), this
*   estimation is very quick.
*
*   Various values of Alpha and Beta can be used to trade among RMS
*   error, peak error, and coefficient complexity.  This program
*   includes a table of the most useful values, and it prints out the
*   resulting RMS and peak errors.
*
* Copyright 1999  Grant R. Griffin
*
*                    The Wide Open License (WOL)
*
* Permission to use, copy, modify, distribute and sell this software
* and its documentation for any purpose is hereby granted without
* fee, provided that the above copyright notice and this license
* appear in all source copies. THIS SOFTWARE IS PROVIDED "AS IS"
* WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND. See
* http://www.dspguru.com/wol.htm for more information.
*
*********************************************************************/
/********************************************************************/
double alpha_beta_mag(double alpha, double beta, double inphase,
                      double quadrature)
{
   /* magnitude ~= alpha * max(|I|, |Q|) + beta * min(|I|, |Q|) */
   double abs_inphase = fabs(inphase);
   double abs_quadrature = fabs(quadrature);
   if (abs_inphase > abs_quadrature) {
      return alpha * abs_inphase + beta * abs_quadrature;
   } else {
      return alpha * abs_quadrature + beta * abs_inphase;
   }
}
/*********************************************************************/
double decibels(double linear)
{
   #define SMALL 1e-20
   if (linear <= SMALL) {
      linear = SMALL;
   }
   return 20.0 * log10(linear);
}
/*********************************************************************/
void test_alpha_beta(char *name, double alpha, double beta,
                     int num_points)
{
   #define PI 3.141592653589793
   int ii;
   double phase, real, imag, err, avg_err, rms_err;
   double peak_err = 0.0;
   double sum_err = 0.0;
   double sum_err_sqrd = 0.0;
   double delta_phase = (2.0 * PI) / num_points;
   for (ii = 0; ii < num_points; ii++) {
      phase = delta_phase * ii;
      real = cos(phase);
      imag = sin(phase);
      err = sqrt(real * real + imag * imag)
            - alpha_beta_mag(alpha, beta, real, imag);
      sum_err += err;
      sum_err_sqrd += err * err;
      err = fabs(err);
      if (err > peak_err) {
         peak_err = err;
      }
   }
   avg_err = sum_err / num_points;
   rms_err = sqrt(sum_err_sqrd / num_points);
   printf("%-16s %14.12lf %14.12lf  %9.6lf %4.1lf %4.1lf\n",
          name, alpha, beta, avg_err, decibels(rms_err),
          decibels(peak_err));
}
/*********************************************************************/
int main(void)
{
   #define NUM_CHECK_POINTS 100000
   typedef struct tagALPHA_BETA {
      char *name;
      double alpha;
      double beta;
   } ALPHA_BETA;
   #define NUM_ALPHA_BETA 12
   const ALPHA_BETA coeff[NUM_ALPHA_BETA] = {
      { "Min RMS Err",      0.947543636291, 0.3924854250920 },
      { "Min Peak Err",     0.960433870103, 0.3978247347593 },
      { "Min RMS w/ Avg=0", 0.948059448969, 0.3926990816987 },
      { "1, Min RMS Err",              1.0,     0.323260990 },
      { "1, Min Peak Err",             1.0,     0.335982538 },
      { "1, 1/2",                      1.0,      1.0 / 2.0  },
      { "1, 1/4",                      1.0,      1.0 / 4.0  },
      { "1, .4",                      1.0,            0.4  },
      { "61/64, 25/64",        61.0 / 64.0,     25.0 / 64.0 },
      { "61/64, 26/64",        61.0 / 64.0,     26.0 / 64.0 },
      { "61/64, 27/64",        61.0 / 64.0,     27.0 / 64.0 },
      { "123/128, 51/128",     123.0 / 128.0,      51.0 / 128.0  },
   };
   int ii;
   printf("\n             Alpha * Max + Beta * Min MagnitudeEstimator\n\n");
   printf("Name                  Alpha           Beta       Avg ErrRMS   Peak\n");
   printf("                                                 (linear)(dB)  (dB)\n");
   printf("---------------------------------------------------------------------\n");
   for (ii = 0; ii < NUM_ALPHA_BETA; ii++) {
      test_alpha_beta(coeff[ii].name, coeff[ii].alpha, coeff[ii].beta,
                      1024);
   }
   return 0;
}
