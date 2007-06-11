c***********************************************************************
c
c  lsm2dMaxNormDiffLOCAL() computes the max norm of the difference 
c  between the two specified scalar fields.
c  The routine loops only over local (narrow band) points. 
c
c  Arguments:
c    max_norm_diff (out):  max norm of the difference between the fields
c    field1 (in):          scalar field 1
c    field2 (in):          scalar field 2
c    index_[xy](in):      [xy] coordinates of local (narrow band) points
c    n*_index(in):         index range of points in index_*
c    *_gb (in):            index range for ghostbox
c    narrow_band(in):    array that marks voxels outside desired fillbox
c    mark_fb(in):        upper limit narrow band value for voxels in 
c                        fillbox
c
c***********************************************************************
      subroutine lsm2dMaxNormDiffLOCAL(
     &  max_norm_diff,
     &  field1,
     &  ilo_field1_gb, ihi_field1_gb,
     &  jlo_field1_gb, jhi_field1_gb,
     &  field2,
     &  ilo_field2_gb, ihi_field2_gb,
     &  jlo_field2_gb, jhi_field2_gb,
     &  index_x,
     &  index_y, 
     &  nlo_index, nhi_index,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb, 
     &  mark_fb)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _ib refers to box to include in norm calculation
      integer ilo_field1_gb, ihi_field1_gb
      integer jlo_field1_gb, jhi_field1_gb
      integer ilo_field2_gb, ihi_field2_gb
      integer jlo_field2_gb, jhi_field2_gb
      double precision field1(ilo_field1_gb:ihi_field1_gb,
     &                        jlo_field1_gb:jhi_field1_gb)
      double precision field2(ilo_field2_gb:ihi_field2_gb,
     &                        jlo_field2_gb:jhi_field2_gb)
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb

c     local variables      
      double precision max_norm_diff
      double precision next_diff
      integer i,j,l


c     initialize max_norm_diff
      i=index_x( nlo_index )
      j=index_y( nlo_index )
      max_norm_diff = abs( field1(i,j) - field2(i,j))

c     { begin loop over indexed points
      do l=nlo_index, nhi_index              
        i=index_x(l)
	j=index_y(l)
	
        if( narrow_band(i,j) .le. mark_fb ) then	
  
        next_diff = abs(field1(i,j) - field2(i,j))
        if (next_diff .gt. max_norm_diff) then
          max_norm_diff = next_diff
        endif
	
	endif
      enddo
c     } end loop over indexed points

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableAdvectionDtLOCAL() computes the stable time step size 
c  for an advection term based on a CFL criterion.
c  
c  Arguments:
c    dt (out):              step size
c    vel_* (in):            components of velocity at t = t_cur
c    *_gb (in):             index range for ghostbox
c    dx, dy (in):           grid spacing
c    index_[xy](in):       [xy] coordinates of local (narrow band) points
c    n*_index(in):         index range of points in index_*
c    narrow_band(in):    array that marks voxels outside desired fillbox
c    mark_fb(in):        upper limit narrow band value for voxels in 
c                        fillbox
c
c***********************************************************************
      subroutine lsm2dComputeStableAdvectionDtLOCAL(
     &  dt,
     &  vel_x, vel_y,
     &  ilo_vel_gb, ihi_vel_gb,
     &  jlo_vel_gb, jhi_vel_gb,
     &  dx, dy,
     &  cfl_number,
     &  index_x,
     &  index_y,  
     &  nlo_index, nhi_index,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb,
     &  mark_fb)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _ib refers to box to include in dt calculation
      integer ilo_vel_gb, ihi_vel_gb
      integer jlo_vel_gb, jhi_vel_gb
      double precision vel_x(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision vel_y(ilo_vel_gb:ihi_vel_gb,
     &                       jlo_vel_gb:jhi_vel_gb)
      double precision dx, dy
      double precision inv_dx, inv_dy
      double precision cfl_number
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb
      
      integer i,j,l
      double precision max_U_over_dX
      double precision U_over_dX_cur
      double precision small_number
      parameter (small_number = 1.d-99)

c     initialize max_U_over_dX to -1
      max_U_over_dX = -1.0d0

c     compute inv_dx, inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy
  
c     { begin loop over indexed points
      do l=nlo_index, nhi_index     
        i=index_x(l)
	j=index_y(l)

       if( narrow_band(i,j) .le. mark_fb ) then	

                U_over_dX_cur = abs(vel_x(i,j))*inv_dx
     &                        + abs(vel_y(i,j))*inv_dy

                if (U_over_dX_cur .gt. max_U_over_dX) then
                  max_U_over_dX = U_over_dX_cur  
                endif
          
          endif
        enddo
c       } end loop over indexed points

c     set dt
      dt = cfl_number / (max_U_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dComputeStableNormalVelDtLOCAL() computes the stable time step 
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
c    dx, dy(in):            grid spacing
c    index_[xy](in):       [xy] coordinates of local (narrow band) points
c    n*_index(in):         index range of points in index_*
c    narrow_band(in):      array that marks voxels outside desired fillbox
c    mark_fb(in):          upper limit narrow band value for voxels in 
c                          fillbox
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableNormalVelDtLOCAL(
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
     &  dx, dy,
     &  cfl_number,
     &  index_x,
     &  index_y,
     &  nlo_index, nhi_index,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb,
     &  mark_fb)
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
      double precision inv_dx, inv_dy
      double precision max_dx_sq
      double precision cfl_number
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb
      
      integer i,j,l
      double precision max_H_over_dX
      double precision H_over_dX_cur
      double precision phi_x_cur, phi_y_cur
      double precision norm_grad_phi
      double precision small_number
      parameter (small_number = 1.d-99)

c     compute max_dx_sq
      max_dx_sq = max(dx,dy)
      max_dx_sq = max(dx,dy) * max(dx,dy)

c     initialize max_H_over_dX to -1
      max_H_over_dX = -1.0d0

c     compute inv_dx, inv_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy
      
c     { begin loop over indexed points
      do l=nlo_index, nhi_index     
        i=index_x(l)
	j=index_y(l)

       if( narrow_band(i,j) .le. mark_fb ) then	

                  phi_x_cur = max(abs(phi_x_plus(i,j)),
     &                          abs(phi_x_minus(i,j)))
                  phi_y_cur = max(abs(phi_y_plus(i,j)),
     &                          abs(phi_y_minus(i,j)))
        
                  norm_grad_phi = sqrt( phi_x_cur*phi_x_cur 
     &                              + phi_y_cur*phi_y_cur + max_dx_sq )

                  H_over_dX_cur = abs(vel_n(i,j)) / norm_grad_phi
     &                        * ( phi_x_cur*inv_dx 
     &                        + phi_y_cur*inv_dy )

                if (H_over_dX_cur .gt. max_H_over_dX) then
                  max_H_over_dX = H_over_dX_cur  
                endif
	      
          endif
        enddo
c       } end loop over indexed points
      
c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dComputeStableConstNormalVelDtLOCAL() computes the stable time step 
c  size for a normal velocity term based on a CFL criterion.
c  
c  Arguments:
c    dt (out):          step size
c    vel_n (in):        normal velocity at t = t_cur, constant for all pts
c    phi_*_plus (in):   components of forward approx to grad(phi) at 
c                       t = t_cur
c    phi_*_minus (in):  components of backward approx to grad(phi) at
c                       t = t_cur
c    index_[xy](in):    [xy] coordinates of local (narrow band) points
c    n*_index(in):      index range of points in index_*
c    narrow_band(in):   array that marks voxels outside desired fillbox
c    mark_fb(in):       upper limit narrow band value for voxels in 
c                       fillbox
c    *_gb (in):         index range for ghostbox
c    dx (in):           grid spacing
c
c  NOTES:
c   - max(phi_*_plus , phi_*_minus) is the value of phi_* that is 
c     used in the time step size calculation.  This may be more 
c     conservative than necessary for Godunov's method, but it is 
c     cheaper to compute.
c
c***********************************************************************
      subroutine lsm2dComputeStableConstNormalVelDtLOCAL(
     &  dt,
     &  vel_n,
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb,
     &  dx, dy,
     &  cfl_number, 
     &  index_x,
     &  index_y,       
     &  nlo_index, nhi_index,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb,
     &  mark_fb)
c***********************************************************************
c { begin subroutine
      implicit none

      double precision dt

c     _gb refers to ghostbox 
c     _fb refers to box to include in dt calculation
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
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
      double precision cfl_number
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb
      
c     local variables    
      integer i,j,l
      double precision inv_dx,inv_dy
      double precision max_dx_sq
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

c     compute inv_dx, ind_dy
      inv_dx = 1.d0/dx
      inv_dy = 1.d0/dy

c     { begin loop over indexed points
      do l=nlo_index, nhi_index     
        i=index_x(l)
	j=index_y(l)

       if( narrow_band(i,j) .le. mark_fb ) then	
     	
        phi_x_cur = max(abs(phi_x_plus(i,j)),
     &                   abs(phi_x_minus(i,j)))
        phi_y_cur = max(abs(phi_y_plus(i,j)),
     &                  abs(phi_y_minus(i,j)))

        H_over_dX_cur = abs(vel_n) 
     &               / sqrt( phi_x_cur*phi_x_cur 
     &                     + phi_y_cur*phi_y_cur)
     &                   * ( phi_x_cur*inv_dx
     &                     + phi_y_cur*inv_dy  + max_dx_sq )

        if (H_over_dX_cur .gt. max_H_over_dX) then
            max_H_over_dX = H_over_dX_cur  
        endif
	
	endif
      enddo
c     } end loop over indexed points

c     set dt
      dt = cfl_number / (max_H_over_dX + small_number);

      return
      end
c } end subroutine
c***********************************************************************