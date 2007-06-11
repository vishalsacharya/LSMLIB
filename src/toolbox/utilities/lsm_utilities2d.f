c***********************************************************************
c
c  File:        lsm_utilities2d.f
c  Copyright:   (c) 2005-2006 Kevin T. Chu
c  Revision:    $Revision: 1.20 $
c  Modified:    $Date: 2007/03/10 05:15:21 $
c  Description: F77 routines for 2D level set method utility subroutines
c
c***********************************************************************

c***********************************************************************
c
c  lsm2dMaxNormDiff() computes the max norm of the difference 
c  between the two specified scalar fields. 
c
c  Arguments:
c    max_norm_diff (out):   max norm of the difference between the fields
c    field1 (in):           scalar field 1
c    field2 (in):           scalar field 2
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include in norm 
c                           calculation
c
c***********************************************************************
      subroutine lsm2dMaxNormDiff(
     &  max_norm_diff,
     &  field1,
     &  ilo_field1_gb, ihi_field1_gb,
     &  jlo_field1_gb, jhi_field1_gb,
     &  field2,
     &  ilo_field2_gb, ihi_field2_gb,
     &  jlo_field2_gb, jhi_field2_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _ib refers to box to include in norm calculation
      integer ilo_field1_gb, ihi_field1_gb
      integer jlo_field1_gb, jhi_field1_gb
      integer ilo_field2_gb, ihi_field2_gb
      integer jlo_field2_gb, jhi_field2_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision field1(ilo_field1_gb:ihi_field1_gb,
     &                        jlo_field1_gb:jhi_field1_gb)
      double precision field2(ilo_field2_gb:ihi_field2_gb,
     &                        jlo_field2_gb:jhi_field2_gb)
      double precision max_norm_diff
      double precision next_diff
      integer i,j

c     initialize max_norm_diff
      max_norm_diff = abs( field1(ilo_ib,jlo_ib) 
     &                   - field2(ilo_ib,jlo_ib))

c       loop over included cells { 
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              next_diff = abs(field1(i,j) - field2(i,j))
              if (next_diff .gt. max_norm_diff) then
                max_norm_diff = next_diff
              endif

          enddo
        enddo
c       } end loop over grid 
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableAdvectionDt() computes the stable time step size 
c  for an advection term based on a CFL criterion.
c  
c  Arguments:
c    dt (out):              step size
c    vel_* (in):            components of velocity at t = t_cur
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx, dy, dz (in):       grid spacing
c
c***********************************************************************
      subroutine lsm2dComputeStableAdvectionDt(
     &  dt,
     &  vel_x, vel_y,
     &  ilo_vel_gb, ihi_vel_gb,
     &  jlo_vel_gb, jhi_vel_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_vel_gb, ihi_vel_gb
      integer jlo_vel_gb, jhi_vel_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_x(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision vel_y(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision dx, dy
      double precision inv_dx, inv_dy
      double precision cfl_number
      integer i, j
      double precision max_U_over_dX
      double precision U_over_dX_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     initialize max_U_over_dX to -1
      max_U_over_dX = -1.0d0

c     compute inv_dx and inv_dx
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

c       loop over included cells {
    
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib
  
              U_over_dX_cur = abs(vel_x(i,j))*inv_dx
     &                    + abs(vel_y(i,j))*inv_dy

              if (U_over_dX_cur .gt. max_U_over_dX) then
                max_U_over_dX = U_over_dX_cur  
              endif
  
          enddo
        enddo
c       } end loop over grid

c     set dt
      dt = cfl_number / (max_U_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableNormalVelDt() computes the stable time step 
c  size for a normal velocity term based on a CFL criterion.
c  
c  Arguments:
c    dt (out):              step size
c    vel_n (in):            normal velocity at t = t_cur
c    phi_*_plus (in):       components of forward approx to grad(phi) at 
c                           t = t_cur
c    phi_*_minus (in):      components of backward approx to grad(phi) at
c                           t = t_cur
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx (in):               grid spacing
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableNormalVelDt(
     &  dt,
     &  vel_n,
     &  ilo_vel_gb, ihi_vel_gb,
     &  jlo_vel_gb, jhi_vel_gb,
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_vel_gb, ihi_vel_gb
      integer jlo_vel_gb, jhi_vel_gb
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_n(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision dx,dy
      double precision inv_dx,inv_dy
      double precision max_dx_sq
      double precision cfl_number
      integer i,j
      double precision max_H_over_dX
      double precision H_over_dX_cur
      double precision phi_x_cur, phi_y_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     compute max_dx_sq
      max_dx_sq = max(dx,dy)
      max_dx_sq = max_dx_sq * max_dx_sq

c     initialize max_H_over_dX to -1
      max_H_over_dX = -1.0d0

c     compute inv_dx and inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              phi_x_cur = max(abs(phi_x_plus(i,j)),
     & 	                      abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))

              H_over_dX_cur = abs(vel_n(i,j)) 
     &                      / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                      * ( phi_x_cur*inv_dx 
     &                        + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif

          enddo
        enddo
c       } end loop over grid
     
c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dComputeStableConstNormalVelDt() computes the stable time step 
c  size for a constant normal velocity term based on a CFL criterion.
c  
c  Arguments:
c    dt (out):              step size
c    vel_n (in):            normal velocity at t = t_cur, constant for all 
c                           points
c    phi_*_plus (in):       components of forward approx to grad(phi) at 
c                           t = t_cur
c    phi_*_minus (in):      components of backward approx to grad(phi) at
c                           t = t_cur
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx, dy (in):           grid spacing in x, y directions
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableConstNormalVelDt(
     &  dt,
     &  vel_n,
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_n
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision dx,dy
      double precision inv_dx,inv_dy
      double precision max_dx_sq
      double precision cfl_number
      integer i,j
      double precision max_H_over_dX
      double precision H_over_dX_cur
      double precision phi_x_cur, phi_y_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     compute max_dx_sq
      max_dx_sq = max(dx,dy)
      max_dx_sq = max_dx_sq * max_dx_sq

c     initialize max_H_over_dX to -1
      max_H_over_dX = -1

c     compute inv_dx and inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              phi_x_cur = max(abs(phi_x_plus(i,j)),
     &       	              abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))

              H_over_dX_cur = abs(vel_n) 
     &                  / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                  * ( phi_x_cur*inv_dx 
     &                    + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif

          enddo
        enddo
c       } end loop over grid
 
c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dVolumeIntegralPhiLessThanZero() computes the volume integral of 
c  the specified function over the region where the level set function 
c  is less than 0.  
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi < 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           Heaviside function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dVolumeIntegralPhiLessThanZero(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx,dy
      double precision epsilon
      integer i,j
      double precision phi_cur
      double precision phi_cur_over_epsilon
      double precision one_minus_H
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      double precision one_over_pi
      parameter (one_over_pi=0.31830988618379d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     initialize int_F to zero
      int_F = 0.0d0

c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon

              if (phi_cur .lt. -epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .lt. epsilon) then
                one_minus_H = 0.5d0*(1.d0 - phi_cur_over_epsilon
     &                                  - one_over_pi
     &                                  * sin(pi*phi_cur_over_epsilon))
                int_F = int_F + one_minus_H*F(i,j)*dV
              endif
     
          enddo
        enddo
c       } end loop over grid
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dVolumeIntegralPhiGreaterThanZero() computes the volume integral 
c  of the specified function over the region where the level set 
c  function is greater than 0.  
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi > 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           Heaviside function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dVolumeIntegralPhiGreaterThanZero(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx,dy
      double precision epsilon
      integer i,j
      double precision phi_cur
      double precision phi_cur_over_epsilon
      double precision H
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      double precision one_over_pi
      parameter (one_over_pi=0.31830988618379d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     initialize int_F to zero
      int_F = 0.0d0

c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon
  
              if (phi_cur .gt. epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .gt. -epsilon) then
                H = 0.5d0*( 1.d0 + phi_cur_over_epsilon 
     &                           + one_over_pi
     &                           * sin(pi*phi_cur_over_epsilon) )
                int_F = int_F + H*F(i,j)*dV
              endif
       
          enddo
        enddo
c       } end loop over grid
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dSurfaceIntegral() computes the surface integral of the specified 
c  function over the region where the level set function equals 0.  
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi = 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    phi_* (in):            components of grad(phi)
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           delta-function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dSurfaceIntegral(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  phi_x, phi_y,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb,
     &  jlo_grad_phi_gb, jhi_grad_phi_gb,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer jlo_grad_phi_gb, jhi_grad_phi_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                       jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi_y(ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                       jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision dx,dy
      double precision epsilon
      double precision one_over_epsilon
      integer i,j
      double precision phi_cur
      double precision delta
      double precision norm_grad_phi
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     compute one_over_epsilon
      one_over_epsilon = 1.d0/epsilon

c     initialize int_F to zero
      int_F = 0.0d0
      
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

              phi_cur = phi(i,j)
  
              if (abs(phi_cur) .lt. epsilon) then
                delta = 0.5d0*one_over_epsilon
     &              * ( 1.d0+cos(pi*phi_cur*one_over_epsilon) ) 

                norm_grad_phi = sqrt(
     &              phi_x(i,j)*phi_x(i,j)
     &            + phi_y(i,j)*phi_y(i,j) )

                int_F = int_F + delta*norm_grad_phi*F(i,j)*dV
              endif
   
          enddo
        enddo
c       } end loop over grid
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dMaxNormDiffControlVolume() computes the max norm of the 
c  difference between the two specified scalar fields in the region 
c  of the computational domain included by the control volume data.
c
c  Arguments:
c    max_norm_diff (out):   max norm of the difference between the fields
c    field1 (in):           scalar field 1
c    field2 (in):           scalar field 2
c    control_vol (in):      control volume data (used to exclude cells
c                           from the max norm calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include in norm 
c                           calculation
c
c***********************************************************************
      subroutine lsm2dMaxNormDiffControlVolume(
     &  max_norm_diff,
     &  field1,
     &  ilo_field1_gb, ihi_field1_gb,
     &  jlo_field1_gb, jhi_field1_gb,
     &  field2,
     &  ilo_field2_gb, ihi_field2_gb,
     &  jlo_field2_gb, jhi_field2_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,     
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _ib refers to box to include in norm calculation
      integer ilo_field1_gb, ihi_field1_gb
      integer jlo_field1_gb, jhi_field1_gb
      integer ilo_field2_gb, ihi_field2_gb
      integer jlo_field2_gb, jhi_field2_gb
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision field1(ilo_field1_gb:ihi_field1_gb,
     &                        jlo_field1_gb:jhi_field1_gb)
      double precision field2(ilo_field2_gb:ihi_field2_gb,
     &                        jlo_field2_gb:jhi_field2_gb)
      double precision control_vol(
     &                   ilo_control_vol_gb:ihi_control_vol_gb,
     &                   jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision max_norm_diff
      double precision next_diff
      integer i,j

c     initialize max_norm_diff
      max_norm_diff = abs( field1(ilo_ib,jlo_ib) 
     &                   - field2(ilo_ib,jlo_ib))

      if (control_vol_sgn .gt. 0) then   
c       loop over included cells { 
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in max norm calculation if it has a 
c           positive control volume
            if (control_vol(i,j) .gt. 0.d0) then

              next_diff = abs(field1(i,j) - field2(i,j))
              if (next_diff .gt. max_norm_diff) then
                max_norm_diff = next_diff
              endif

            endif

          enddo
        enddo
c       } end loop over grid 

      else
c       loop over included cells { 
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in max norm calculation if it has a 
c           negative control volume
            if (control_vol(i,j) .lt. 0.d0) then

              next_diff = abs(field1(i,j) - field2(i,j))
              if (next_diff .gt. max_norm_diff) then
                max_norm_diff = next_diff
              endif

            endif

          enddo
        enddo
c       } end loop over grid 
      endif
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableAdvectionDtControlVolume() computes the stable 
c  time step size for an advection term based on a CFL criterion for
c  grid cells within the computational domain included by the control
c  volume data.
c  
c  Arguments:
c    dt (out):              step size
c    vel_* (in):            components of velocity at t = t_cur
c    control_vol (in):      control volume data (used to exclude cells
c                           from the calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx, dy, dz (in):       grid spacing
c
c***********************************************************************
      subroutine lsm2dComputeStableAdvectionDtControlVolume(
     &  dt,
     &  vel_x, vel_y,
     &  ilo_vel_gb, ihi_vel_gb,
     &  jlo_vel_gb, jhi_vel_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_vel_gb, ihi_vel_gb
      integer jlo_vel_gb, jhi_vel_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_x(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision vel_y(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      double precision control_vol(
     &                   ilo_control_vol_gb:ihi_control_vol_gb,
     &                   jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx, dy
      double precision inv_dx, inv_dy
      double precision cfl_number
      integer i, j
      double precision max_U_over_dX
      double precision U_over_dX_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     initialize max_U_over_dX to -1
      max_U_over_dX = -1.0d0

c     compute inv_dx and inv_dx
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy
      
      if (control_vol_sgn .gt. 0) then   
c       loop over included cells {
    
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib
c           only include cell in dt calculation if it has a 
c           positive control volume
            if (control_vol(i,j) .gt. 0.d0) then  
              U_over_dX_cur = abs(vel_x(i,j))*inv_dx
     &                    + abs(vel_y(i,j))*inv_dy

              if (U_over_dX_cur .gt. max_U_over_dX) then
                max_U_over_dX = U_over_dX_cur  
              endif
            endif	      
          enddo
        enddo
c       } end loop over grid

      else
c       loop over included cells {   
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib
c           only include cell in dt calculation if it has a 
c           negative control volume
            if (control_vol(i,j) .lt. 0.d0) then  
              U_over_dX_cur = abs(vel_x(i,j))*inv_dx
     &                    + abs(vel_y(i,j))*inv_dy

              if (U_over_dX_cur .gt. max_U_over_dX) then
                max_U_over_dX = U_over_dX_cur  
              endif
            endif	      
          enddo
        enddo
c       } end loop over grid
      endif      

c     set dt
      dt = cfl_number / (max_U_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableNormalVelDtControlVolume() computes the stable 
c  time step size for a normal velocity term based on a CFL criterion
c  for grid cells within the computational domain included by the 
c  control volume data.
c  
c  Arguments:
c    dt (out):              step size
c    vel_n (in):            normal velocity at t = t_cur
c    phi_*_plus (in):       components of forward approx to grad(phi) at 
c                           t = t_cur
c    phi_*_minus (in):      components of backward approx to grad(phi) at
c                           t = t_cur
c    control_vol (in):      control volume data (used to exclude cells
c                           from the calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx (in):               grid spacing
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableNormalVelDtControlVolume(
     &  dt,
     &  vel_n,
     &  ilo_vel_gb, ihi_vel_gb,
     &  jlo_vel_gb, jhi_vel_gb,
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_vel_gb, ihi_vel_gb
      integer jlo_vel_gb, jhi_vel_gb
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_n(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      double precision control_vol(
     &                   ilo_control_vol_gb:ihi_control_vol_gb,
     &                   jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx,dy
      double precision inv_dx,inv_dy
      double precision max_dx_sq
      double precision cfl_number
      integer i,j
      double precision max_H_over_dX
      double precision H_over_dX_cur
      double precision phi_x_cur, phi_y_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     compute max_dx_sq
      max_dx_sq = max(dx,dy)
      max_dx_sq = max_dx_sq * max_dx_sq

c     initialize max_H_over_dX to -1
      max_H_over_dX = -1.0d0

c     compute inv_dx and inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

      if (control_vol_sgn .gt. 0) then
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib
c           only include cell in dt calculation if it has a 
c           positive control volume
            if (control_vol(i,j) .gt. 0.d0) then  
              phi_x_cur = max(abs(phi_x_plus(i,j)),
     & 	                      abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))

              H_over_dX_cur = abs(vel_n(i,j)) 
     &                      / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                      * ( phi_x_cur*inv_dx 
     &                        + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif
            endif
          enddo
        enddo
c       } end loop over grid

      else      
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib
c           only include cell in dt calculation if it has a 
c           negative control volume
            if (control_vol(i,j) .lt. 0.d0) then  
              phi_x_cur = max(abs(phi_x_plus(i,j)),
     & 	                      abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))
              H_over_dX_cur = abs(vel_n(i,j)) 
     &                      / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                      * ( phi_x_cur*inv_dx 
     &                        + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif
            endif
          enddo
        enddo
c       } end loop over grid

      endif
     
c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dComputeStableConstNormalVelDtControlVolume() computes the 
c  stable time step size for a constant normal velocity term based on 
c  a CFL criterion for grid cells within the computational domain 
c  included by the control volume data.
c  
c  Arguments:
c    dt (out):              step size
c    vel_n (in):            normal velocity at t = t_cur, constant for all 
c                           points
c    phi_*_plus (in):       components of forward approx to grad(phi) at 
c                           t = t_cur
c    phi_*_minus (in):      components of backward approx to grad(phi) at
c                           t = t_cur
c    control_vol (in):      control volume data (used to exclude cells
c                           from the calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for box to include dt calculation
c    dx, dy (in):           grid spacing in x, y directions
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableConstNormalVelDtControlVolume(
     &  dt,
     &  vel_n,
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  cfl_number)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision vel_n
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                   jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                   jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      double precision control_vol(
     &                   ilo_control_vol_gb:ihi_control_vol_gb,
     &                   jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx,dy
      double precision inv_dx,inv_dy
      double precision max_dx_sq
      double precision cfl_number
      integer i,j
      double precision max_H_over_dX
      double precision H_over_dX_cur
      double precision phi_x_cur, phi_y_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     compute max_dx_sq
      max_dx_sq = max(dx,dy)
      max_dx_sq = max_dx_sq * max_dx_sq

c     initialize max_H_over_dX to -1
      max_H_over_dX = -1

c     compute inv_dx and inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

      if (control_vol_sgn .gt. 0) then
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in dt calculation if it has a 
c           positive control volume
            if (control_vol(i,j) .gt. 0.d0) then  
              phi_x_cur = max(abs(phi_x_plus(i,j)),
     &       	              abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))

              H_over_dX_cur = abs(vel_n) 
     &                  / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                  * ( phi_x_cur*inv_dx 
     &                    + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif

            endif
          enddo
        enddo
c       } end loop over grid
      else
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in dt calculation if it has a 
c           negative control volume
            if (control_vol(i,j) .lt. 0.d0) then  
              phi_x_cur = max(abs(phi_x_plus(i,j)),
     &       	              abs(phi_x_minus(i,j)))
              phi_y_cur = max(abs(phi_y_plus(i,j)),
     &	                      abs(phi_y_minus(i,j)))
              H_over_dX_cur = abs(vel_n) 
     &                  / sqrt( phi_x_cur*phi_x_cur 
     &                        + phi_y_cur*phi_y_cur )
     &                  * ( phi_x_cur*inv_dx 
     &                    + phi_y_cur*inv_dy + max_dx_sq )

              if (H_over_dX_cur .gt. max_H_over_dX) then
                max_H_over_dX = H_over_dX_cur  
              endif

            endif
          enddo
        enddo
c       } end loop over grid
      endif
      
c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dVolumeIntegralPhiLessThanZeroControlVolume() computes the 
c  volume integral of the specified function over the region of the 
c  computational domain where the level set function is less than 0.  
c  The computational domain contains only those cells that are included
c  by the control volume data.
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi < 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    control_vol (in):      control volume data (used to exclude cells
c                           from the integral calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume 
c                           points should be used
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           Heaviside function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dVolumeIntegralPhiLessThanZeroControlVolume(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision control_vol(
     &                     ilo_control_vol_gb:ihi_control_vol_gb,
     &                     jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx,dy
      double precision epsilon
      integer i,j
      double precision phi_cur
      double precision phi_cur_over_epsilon
      double precision one_minus_H
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      double precision one_over_pi
      parameter (one_over_pi=0.31830988618379d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     initialize int_F to zero
      int_F = 0.0d0

      if (control_vol_sgn .gt. 0) then
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a positive control volume
            if (control_vol(i,j) .gt. 0.d0) then

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon

              if (phi_cur .lt. -epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .lt. epsilon) then
                one_minus_H = 0.5d0*(1.d0 - phi_cur_over_epsilon
     &                                  - one_over_pi
     &                                  * sin(pi*phi_cur_over_epsilon))
                int_F = int_F + one_minus_H*F(i,j)*dV
              endif

            endif
      
          enddo
        enddo
c       } end loop over grid
    
      else
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a negative control volume
            if (control_vol(i,j) .lt. 0.d0) then

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon

              if (phi_cur .lt. -epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .lt. epsilon) then
                one_minus_H = 0.5d0*(1.d0 - phi_cur_over_epsilon
     &                                  - one_over_pi
     &                                  * sin(pi*phi_cur_over_epsilon))
                int_F = int_F + one_minus_H*F(i,j)*dV
              endif

            endif
      
          enddo
        enddo
c       } end loop over grid      

      endif
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dVolumeIntegralPhiGreaterThanZeroControlVolume() computes the 
c  volume integral of the specified function over the region of the 
c  computational domain where the level set function is greater than 0.  
c  The computational domain contains only those cells that are included
c  by the control volume data.
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi > 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    control_vol (in):      control volume data (used to exclude cells
c                           from the integral calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           Heaviside function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dVolumeIntegralPhiGreaterThanZeroControlVolume(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision control_vol(
     &                     ilo_control_vol_gb:ihi_control_vol_gb,
     &                     jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx,dy
      double precision epsilon
      integer i,j
      double precision phi_cur
      double precision phi_cur_over_epsilon
      double precision H
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      double precision one_over_pi
      parameter (one_over_pi=0.31830988618379d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     initialize int_F to zero
      int_F = 0.0d0

      if (control_vol_sgn .gt. 0) then
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a positive control volume
            if (control_vol(i,j) .gt. 0.d0) then

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon
  
              if (phi_cur .gt. epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .gt. -epsilon) then
                H = 0.5d0*( 1.d0 + phi_cur_over_epsilon 
     &                           + one_over_pi
     &                           * sin(pi*phi_cur_over_epsilon) )
                int_F = int_F + H*F(i,j)*dV
              endif

            endif
        
          enddo
        enddo
c       } end loop over grid

      else
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a negative control volume
            if (control_vol(i,j) .lt. 0.d0) then

              phi_cur = phi(i,j)
              phi_cur_over_epsilon = phi_cur/epsilon
  
              if (phi_cur .gt. epsilon) then
                int_F = int_F + F(i,j)*dV
              elseif (phi_cur .gt. -epsilon) then
                H = 0.5d0*( 1.d0 + phi_cur_over_epsilon 
     &                           + one_over_pi
     &                           * sin(pi*phi_cur_over_epsilon) )
                int_F = int_F + H*F(i,j)*dV
              endif

            endif
        
          enddo
        enddo
c       } end loop over grid

      endif
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dSurfaceIntegralControlVolume() computes the surface integral 
c  of the specified function over the region of the computational 
c  domain where the level set function equals 0.  The computational 
c  domain contains only those cells that are included by the control 
c  volume data.
c
c  Arguments:
c    int_F (out):           value of integral of F over the region 
c                           where phi = 0
c    F (in):                function to be integrated 
c    phi (in):              level set function
c    phi_* (in):            components of grad(phi)
c    control_vol (in):      control volume data (used to exclude cells
c                           from the integral calculation)
c    control_vol_sgn (in):  1 (-1) if positive (negative) control volume
c                           points should be used
c    dx, dy (in):           grid spacing
c    epsilon (in):          width of numerical smoothing to use for 
c                           delta-function
c    *_gb (in):             index range for ghostbox
c    *_ib (in):             index range for interior box
c
c***********************************************************************
      subroutine lsm2dSurfaceIntegralControlVolume(
     &  int_F,
     &  F,
     &  ilo_F_gb, ihi_F_gb,
     &  jlo_F_gb, jhi_F_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  jlo_phi_gb, jhi_phi_gb,
     &  phi_x, phi_y,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb,
     &  jlo_grad_phi_gb, jhi_grad_phi_gb,
     &  control_vol,
     &  ilo_control_vol_gb, ihi_control_vol_gb,
     &  jlo_control_vol_gb, jhi_control_vol_gb,
     &  control_vol_sgn,
     &  ilo_ib, ihi_ib,
     &  jlo_ib, jhi_ib,
     &  dx, dy,
     &  epsilon)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision int_F

c     _gb refers to ghostbox 
c     _ib refers to box to include in integral calculation
      integer ilo_F_gb, ihi_F_gb
      integer jlo_F_gb, jhi_F_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer jlo_grad_phi_gb, jhi_grad_phi_gb
      integer ilo_control_vol_gb, ihi_control_vol_gb
      integer jlo_control_vol_gb, jhi_control_vol_gb
      integer ilo_ib, ihi_ib
      integer jlo_ib, jhi_ib
      double precision F(ilo_F_gb:ihi_F_gb,
     &                   jlo_F_gb:jhi_F_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                       jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi_y(ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                       jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision control_vol(
     &                     ilo_control_vol_gb:ihi_control_vol_gb,
     &                     jlo_control_vol_gb:jhi_control_vol_gb)
      integer control_vol_sgn
      double precision dx,dy
      double precision epsilon
      double precision one_over_epsilon
      integer i,j
      double precision phi_cur
      double precision delta
      double precision norm_grad_phi
      double precision dV
      double precision pi
      parameter (pi=3.14159265358979323846d0)
      

c     compute dV = dx * dy
      dV = dx * dy

c     compute one_over_epsilon
      one_over_epsilon = 1.d0/epsilon

c     initialize int_F to zero
      int_F = 0.0d0
      
      if (control_vol_sgn .gt. 0) then
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a positive control volume
            if (control_vol(i,j) .gt. 0.d0) then

              phi_cur = phi(i,j)
  
              if (abs(phi_cur) .lt. epsilon) then
                delta = 0.5d0*one_over_epsilon
     &              * ( 1.d0+cos(pi*phi_cur*one_over_epsilon) ) 

                norm_grad_phi = sqrt(
     &              phi_x(i,j)*phi_x(i,j)
     &            + phi_y(i,j)*phi_y(i,j) )

                int_F = int_F + delta*norm_grad_phi*F(i,j)*dV
              endif

            endif
      
          enddo
        enddo
c       } end loop over grid

      else
c       loop over included cells {
        do j=jlo_ib,jhi_ib
          do i=ilo_ib,ihi_ib

c           only include cell in integral if it has a positive control volume
            if (control_vol(i,j) .lt. 0.d0) then

              phi_cur = phi(i,j)
  
              if (abs(phi_cur) .lt. epsilon) then
                delta = 0.5d0*one_over_epsilon
     &              * ( 1.d0+cos(pi*phi_cur*one_over_epsilon) ) 

                norm_grad_phi = sqrt(
     &              phi_x(i,j)*phi_x(i,j)
     &            + phi_y(i,j)*phi_y(i,j) )

                int_F = int_F + delta*norm_grad_phi*F(i,j)*dV
              endif

            endif
      
          enddo
        enddo
c       } end loop over grid      

      endif
      
      return
      end
c } end subroutine
c***********************************************************************

