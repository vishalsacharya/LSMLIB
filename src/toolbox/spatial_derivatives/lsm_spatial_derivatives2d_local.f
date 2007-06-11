c***********************************************************************
c
c  lsm2dComputeDnLOCAL() computes the n-th undivided differences in the 
c  specified direction given the (n-1)-th undivided differences.  The 
c  subroutine assumes that valid data for the (n-1)-th undivided 
c  differences is only available n/2 or (n+1)/2 (depending on the parity 
c  of n) cells in from the boundary of the ghost-cell box.  The 
c  undivided differences in cells with insufficient data is set to a 
c  large number. 
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    Dn (out):           n-th undivided differences 
c    Dn_minus_one (in):  (n-1)-th undivided differences 
c    n (in):             order of undivided differences to compute
c    *_gb (in):          index range for ghostbox
c    index_[xy](in):     [xy] coordinates of local (narrow band) points
c    n*_index(in):       index range of points to loop over in index_*
c    narrow_band(in):    array that marks voxels outside desired fillbox
c    mark_fb(in):        upper limit narrow band value for voxels in 
c                        fillbox
c
c  NOTES:
c   - The index ranges for all ghostboxes and the fillbox should 
c     correspond to the index range for cell-centered data.
c   - The ghostbox for Dn_minus_one MUST be at least one ghostcell width
c     larger than the fillbox.
c
c***********************************************************************
      subroutine lsm2dComputeDnLOCAL(
     &  Dn,
     &  ilo_Dn_gb, ihi_Dn_gb, 
     &  jlo_Dn_gb, jhi_Dn_gb, 
     &  Dn_minus_one,
     &  ilo_Dn_minus_one_gb, ihi_Dn_minus_one_gb, 
     &  jlo_Dn_minus_one_gb, jhi_Dn_minus_one_gb, 
     &  n,
     &  dir,
     &  index_x, index_y,
     &  nlo_index, nhi_index,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb, 
     &  mark_fb)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _fb refers to fillbox 
      integer ilo_Dn_gb, ihi_Dn_gb
      integer jlo_Dn_gb, jhi_Dn_gb
      integer ilo_Dn_minus_one_gb, ihi_Dn_minus_one_gb
      integer jlo_Dn_minus_one_gb, jhi_Dn_minus_one_gb
      double precision Dn(ilo_Dn_gb:ihi_Dn_gb,
     &                    jlo_Dn_gb:jhi_Dn_gb)
      double precision Dn_minus_one(
     &                   ilo_Dn_minus_one_gb:ihi_Dn_minus_one_gb,
     &                   jlo_Dn_minus_one_gb:jhi_Dn_minus_one_gb)
      integer n
      integer dir
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb     
            
      integer i,j,l
      integer offset(1:2)
      integer fillbox_shift(1:2)
      double precision sign_multiplier
      double precision big
      parameter (big=1.d10)

c     calculate offsets, fillbox shifts, and sign_multiplier used 
c     when computing undivided differences.
c     NOTE:  even and odd undivided differences are taken in
c            opposite order because of the discrepancy between
c            face- and cell-centered data.  the sign discrepancy 
c            is taken into account by sign_multiplier
      do i=1,2
        offset(i) = 0
        fillbox_shift(i) = 0
      enddo
      if (mod(n,2).eq.1) then
        offset(dir) = 1
        sign_multiplier = 1.0
        fillbox_shift(dir) = 1
      else
        offset(dir) = -1
        sign_multiplier = -1.0
        fillbox_shift(dir) = 0
      endif

c     loop over indexed points only {
      do l= nlo_index, nhi_index      
        i = index_x(l) 
	j = index_y(l)
        if( narrow_band(i,j) .le. mark_fb ) then	
              Dn(i,j) = sign_multiplier
     &          * ( Dn_minus_one(i,j)
     &            - Dn_minus_one(i-offset(1),j-offset(2)) )          
        else
	      Dn(i,j) = big
	endif
      
      enddo
c     }  end loop over indexed points 

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dHJENO1LOCAL() computes the forward (plus) and backward (minus)
c  first-order Hamilton-Jacobi ENO approximations to the gradient of 
c  phi.
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction 
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi
c    D1 (in):            scratch space for holding undivided first-differences
c    dx, dy(in):         grid spacing
c    *_gb (in):          index range for ghostbox
c    index_[xy](in):     [xy] coordinates of local (narrow band) points
c    n*_index[01](in):   index range of points in index_* that are in
c                        level [01] of the narrow band
c    narrow_band(in):    array that marks voxels outside desired fillbox
c    mark_*(in):         upper limit narrow band value for voxels in 
c                        the appropriate fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus AND minus derivatives have
c     the same fillbox
c   - index_[xy] arrays range at minimum from nlo_index0 to nhi_index1
c
c***********************************************************************
      subroutine lsm2dHJENO1LOCAL(
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb, 
     &  jlo_D1_gb, jhi_D1_gb,
     &  dx, dy,
     &  index_x, index_y,
     &  nlo_index0, nhi_index0,
     &  nlo_index1, nhi_index1,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb, 
     &  mark_fb,
     &  mark_D1)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer jlo_D1_gb, jhi_D1_gb
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                    jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                    jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                    jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                    jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb,
     &                    jlo_D1_gb:jhi_D1_gb)
      double precision dx, dy
      integer nlo_index0, nhi_index0
      integer nlo_index1, nhi_index1
      integer index_x(nlo_index0:nhi_index1)
      integer index_y(nlo_index0:nhi_index1)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb, mark_D1     
      
      double precision inv_dx, inv_dy
      integer i,j,l
      double precision zero
      parameter (zero=0.0d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order
      parameter (order=1)
      integer x_dir, y_dir
      parameter (x_dir=1,y_dir=2)


c     compute inv_dx, inv_dy
      inv_dx = 1.0d0/dx
      inv_dy = 1.0d0/dy

c----------------------------------------------------
c    compute phi_x_plus and phi_x_minus
c----------------------------------------------------
c     compute first undivided differences in x-direction
      call lsm2dComputeDnLOCAL(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb, 
     &                    phi,
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    jlo_phi_gb, jhi_phi_gb, 
     &                    order, x_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index1,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D1)

c    loop over  narrow band level 0 points only {
      do l = nlo_index0, nhi_index0       
        i = index_x(l)
	j = index_y(l)
	
c       include only fill box points (marked appropriately)
        if( narrow_band(i,j) .le. mark_fb ) then	

            phi_x_plus(i,j) = D1(i+1,j)*inv_dx
            phi_x_minus(i,j) = D1(i,j)*inv_dx
   
        endif
      enddo
c     } end loop over narrow band points

c----------------------------------------------------
c    compute phi_y_plus and phi_y_minus
c----------------------------------------------------
c     compute first undivided differences in y-direction
      call lsm2dComputeDnLOCAL(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb, 
     &                    phi,
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    jlo_phi_gb, jhi_phi_gb, 
     &                    order, y_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index1,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D1)

c    loop over  narrow band level 0 points only {
      do l = nlo_index0, nhi_index0       
        i = index_x(l)
	j = index_y(l)
	
c       include only fill box points (marked appropriately)
        if( narrow_band(i,j) .le. mark_fb ) then	

            phi_y_minus(i,j) = D1(i,j)*inv_dy
            phi_y_plus(i,j)  = D1(i,j+1)*inv_dy
   
        endif
      enddo
c     } end loop over narrow band points 

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dHJENO2LOCAL() computes the forward (plus) and backward (minus)
c  second-order Hamilton-Jacobi ENO approximations to the gradient of 
c  phi.
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction 
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi
c    D1 (in):            scratch space for holding undivided first-differences
c    D2 (in):            scratch space for holding undivided second-differences
c    dx, dy (in):        grid spacing
c    *_gb (in):          index range for ghostbox
c    index_[xy](in):     [xy] coordinates of local (narrow band) points
c    n*_index[012](in):  index range of points in index_* that are in
c                        level [012] of the narrow band
c    narrow_band(in):    array that marks voxels outside desired fillbox
c    mark_*(in):         upper limit narrow band value for voxels in 
c                        the appropriate fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus and minus derivatives have
c     the same fillbox
c   - index_[xy] arrays range at minimum from nlo_index0 to nhi_index2
c
c***********************************************************************
      subroutine lsm2dHJENO2LOCAL(
     &  phi_x_plus, phi_y_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb,
     &  phi_x_minus, phi_y_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb, 
     &  jlo_D1_gb, jhi_D1_gb,
     &  D2,
     &  ilo_D2_gb, ihi_D2_gb, 
     &  jlo_D2_gb, jhi_D2_gb,
     &  dx, dy,
     &  index_x,
     &  index_y, 
     &  nlo_index0, nhi_index0,
     &  nlo_index1, nhi_index1,
     &  nlo_index2, nhi_index2,
     &  narrow_band,
     &  ilo_nb_gb, ihi_nb_gb, 
     &  jlo_nb_gb, jhi_nb_gb, 
     &  mark_fb,
     &  mark_D1,
     &  mark_D2)
     
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer jlo_grad_phi_plus_gb, jhi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer jlo_grad_phi_minus_gb, jhi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer jlo_D1_gb, jhi_D1_gb
      integer ilo_D2_gb, ihi_D2_gb
      integer jlo_D2_gb, jhi_D2_gb
      integer nlo_index0, nhi_index0
      integer nlo_index1, nhi_index1
      integer nlo_index2, nhi_index2
      integer index_x(nlo_index0:nhi_index2)
      integer index_y(nlo_index0:nhi_index2)
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                    jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_y_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb,
     &                    jlo_grad_phi_plus_gb:jhi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                    jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi_y_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb,
     &                    jlo_grad_phi_minus_gb:jhi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb,
     &                    jlo_D1_gb:jhi_D1_gb)
      double precision D2(ilo_D2_gb:ihi_D2_gb,
     &                    jlo_D2_gb:jhi_D2_gb)
      double precision dx, dy
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_D2
      integer*1 mark_D1
      integer*1 mark_fb
      
      double precision inv_dx, inv_dy
      integer i,j,l
      double precision zero, half
      parameter (zero=0.0d0, half=0.5d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1, order_2
      parameter (order_1=1,order_2=2)
      integer x_dir, y_dir
      parameter (x_dir=1,y_dir=2)

c     compute inv_dx, inv_dy
      inv_dx = 1.0d0/dx
      inv_dy = 1.0d0/dy

c----------------------------------------------------
c    compute phi_x_plus and phi_x_minus
c----------------------------------------------------
c     compute first undivided differences in x-direction
c     for now, these are computed everywhere (and not only in narrow band)
      call lsm2dComputeDnLOCAL(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb,
     &                    phi,
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    jlo_phi_gb, jhi_phi_gb,
     &                    order_1, x_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index2,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D1) 

c     compute second undivided differences x-direction
      call lsm2dComputeDnLOCAL(D2, 
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    jlo_D2_gb, jhi_D2_gb,
     &                    D1,
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb,
     &                    order_2, x_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index1,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D2) 
c    loop over narrow band level 0 points {
      do l=nlo_index0, nhi_index0   
        i=index_x(l)
	j=index_y(l)

c       include only fill box points (marked appropriately)
        if( narrow_band(i,j) .le. mark_fb ) then
	
c             phi_x_plus
              if (abs(D2(i,j)).lt.abs(D2(i+1,j))) then
        	phi_x_plus(i,j) = (D1(i+1,j) 
     &                            - half*D2(i,j))*inv_dx
              else
        	phi_x_plus(i,j) = (D1(i+1,j) 
     &                            - half*D2(i+1,j))*inv_dx
              endif

c             phi_x_minus
              if (abs(D2(i-1,j)).lt.abs(D2(i,j))) then
        	phi_x_minus(i,j) = (D1(i,j) 
     &                             + half*D2(i-1,j))*inv_dx
              else
        	phi_x_minus(i,j) = (D1(i,j) 
     &                             + half*D2(i,j))*inv_dx
              endif
        endif	      
      enddo
c     } end loop over indexed points


c----------------------------------------------------
c    compute phi_y_plus and phi_y_minus
c----------------------------------------------------
c     compute first undivided differences in y-direction
      call lsm2dComputeDnLOCAL(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb,
     &                    phi,
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    jlo_phi_gb, jhi_phi_gb,
     &                    order_1, y_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index2,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D1) 
     
c     compute second undivided differences in y-direction
      call lsm2dComputeDnLOCAL(D2, 
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    jlo_D2_gb, jhi_D2_gb,
     &                    D1,
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    jlo_D1_gb, jhi_D1_gb,
     &                    order_2, y_dir,
     &                    index_x, index_y,
     &                    nlo_index0, nhi_index1,
     &                    narrow_band,     
     &                    ilo_nb_gb, ihi_nb_gb, 
     &                    jlo_nb_gb, jhi_nb_gb,
     &                    mark_D2)
      
c    loop over  narrow band level 0 points only {
      do l = nlo_index0, nhi_index0       
        i = index_x(l)
	j = index_y(l)
	
c       include only fill box points (marked appropriately)
        if( narrow_band(i,j) .le. mark_fb ) then	
c             phi_y_plus
              if (abs(D2(i,j)).lt.abs(D2(i,j+1))) then
        	phi_y_plus(i,j) = (D1(i,j+1) 
     &                            - half*D2(i,j))*inv_dy
              else
        	phi_y_plus(i,j) = (D1(i,j+1) 
     &                            - half*D2(i,j+1))*inv_dy
              endif

c             phi_y_minus
              if (abs(D2(i,j-1)).lt.abs(D2(i,j))) then
        	phi_y_minus(i,j) = (D1(i,j) 
     &                             + half*D2(i,j-1))*inv_dy
              else
        	phi_y_minus(i,j) = (D1(i,j) 
     &                             + half*D2(i,j))*inv_dy
              endif
	endif      
      enddo
c     } end loop over narrow band points

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dCentralGradOrder2LOCAL() computes the second-order central 
c  approximation to the gradient of phi.
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    phi_* (out):      components of grad(phi) 
c    phi (in):         phi
c    dx, dy (in):      grid spacing
c    *_gb (in):        index range for ghostbox
c    index_[xy](in):   [xy] coordinates of local (narrow band) points
c    n*_index(in):     index range of points to loop over in index_*
c    narrow_band(in):  array that marks voxels outside desired fillbox
c    mark_fb(in):      upper limit narrow band value for voxels in 
c                      fillbox
c
c***********************************************************************
      subroutine lsm2dCentralGradOrder2LOCAL(
     &  phi_x, phi_y,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  jlo_grad_phi_gb, jhi_grad_phi_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb,
     &  dx, dy,
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

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer jlo_grad_phi_gb, jhi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      double precision phi_x(
     &                    ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                    jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi_y(
     &                    ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                    jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx, dy
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
      double precision dx_factor, dy_factor

c     compute denominator values
      dx_factor = 0.5d0/dx
      dy_factor = 0.5d0/dy

c     { begin loop over indexed points
      do l= nlo_index, nhi_index      
        i=index_x(l)
	j=index_y(l)

c       include only fill box points (marked appropriately)	
        if( narrow_band(i,j) .le. mark_fb ) then
         
          phi_x(i,j) = (phi(i+1,j) - phi(i-1,j))*dx_factor
          phi_y(i,j) = (phi(i,j+1) - phi(i,j-1))*dy_factor
	  
	endif  
      enddo
c     } end loop over indexed points
      
      
      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dCentralGradOrder4LOCAL() computes the second-order, central, 
c  finite difference approximation to the gradient of phi.
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    phi_* (out):      components of grad(phi) 
c    phi (in):         phi
c    dx, dy (in):      grid spacing
c    *_gb (in):        index range for ghostbox
c    index_[xy](in):   [xy] coordinates of local (narrow band) points
c    n*_index(in):     index range of points to loop over in index_*
c    narrow_band(in):  array that marks voxels outside desired fillbox
c    mark_fb(in):      upper limit narrow band value for voxels in 
c                      fillbox
c
c***********************************************************************
      subroutine lsm2dCentralGradOrder4LOCAL(
     &  phi_x, phi_y,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  jlo_grad_phi_gb, jhi_grad_phi_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb,
     &  dx, dy,
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

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer jlo_grad_phi_gb, jhi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      double precision phi_x(
     &                    ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                    jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi_y(
     &                    ilo_grad_phi_gb:ihi_grad_phi_gb,
     &                    jlo_grad_phi_gb:jhi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx, dy
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb
      
      integer i,j,l
      double precision dx_factor, dy_factor
      double precision eight
      parameter (eight = 8.0d0)

c     compute denominator values
      dx_factor = 0.0833333333333333333332d0/dx
      dy_factor = 0.0833333333333333333332d0/dy

c     { begin loop over indexed points
      do l= nlo_index, nhi_index      
        i=index_x(l)
	j=index_y(l)

c       include only fill box points (marked appropriately)	
        if( narrow_band(i,j) .le. mark_fb ) then

            phi_x(i,j) = ( -phi(i+2,j) + eight*phi(i+1,j) 
     &                     +phi(i-2,j) - eight*phi(i-1,j) )
     &                   * dx_factor
            phi_y(i,j) = ( -phi(i,j+2) + eight*phi(i,j+1) 
     &                     +phi(i,j-2) - eight*phi(i,j-1) )
     &                   * dy_factor
          
        endif
      enddo
c     } end loop over indexed points 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm2dLaplacianOrder2LOCAL() computes the second-order, central, 
c  finite difference approximation to the Laplacian of phi.
c  The routine loops only over local (narrow band) points.
c
c  Arguments:
c    laplacian_phi (out):  Laplacian of phi
c    phi (in):             phi
c    dx (in):              grid spacing
c    *_gb (in):            index range for ghostbox
c    index_[xy](in):       [xy] coordinates of local (narrow band) points
c    n*_index(in):         index range of points to loop over in index_*
c    narrow_band(in):      array that marks voxels outside desired fillbox
c    mark_fb(in):          upper limit narrow band value for voxels in 
c                          fillbox
c
c***********************************************************************
      subroutine lsm2dLaplacianOrder2LOCAL(
     &  laplacian_phi,
     &  ilo_laplacian_phi_gb, ihi_laplacian_phi_gb, 
     &  jlo_laplacian_phi_gb, jhi_laplacian_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb, 
     &  dx, dy,
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

c     _laplacian_phi_gb refers to ghostbox for laplacian_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_laplacian_phi_gb, ihi_laplacian_phi_gb
      integer jlo_laplacian_phi_gb, jhi_laplacian_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      double precision laplacian_phi(
     &                   ilo_laplacian_phi_gb:ihi_laplacian_phi_gb,
     &                   jlo_laplacian_phi_gb:jhi_laplacian_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx, dy
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb
            
      integer i, j, l
      double precision inv_dx_sq
      double precision inv_dy_sq

c     compute denominator values
      inv_dx_sq = 1.0d0/dx/dx
      inv_dy_sq = 1.0d0/dy/dy

c     { begin loop over indexed points
      do l= nlo_index, nhi_index      
        i=index_x(l)
	j=index_y(l)

c       include only fill box points (marked appropriately)	
        if( narrow_band(i,j) .le. mark_fb ) then

            laplacian_phi(i,j) = 
     &        inv_dx_sq *
     &        ( phi(i+1,j) - 2.0d0*phi(i,j) + phi(i-1,j) ) 
     &      + inv_dy_sq *
     &        ( phi(i,j+1) - 2.0d0*phi(i,j) + phi(i,j-1) ) 
           
        endif
      enddo
c     } end loop over indexed points 

      return
      end
c } end subroutine
c***********************************************************************


c***********************************************************************
c
c  lsm2dComputeAveGradPhiLocal() computes the average of the 
c  second-order, central, finite difference approximation to the 
c  gradient of phi within the narrow band.
c  The routine loops only over local (narrow band) points. 
c
c  Arguments:
c    phi (in):          phi
c    grad_phi_ave(out): average of the gradient 
c    dx, dy(in):        grid spacing
c    index_[xy](in):    [xy] coordinates of local (narrow band) points
c    n*_index(in):      index range of points to loop over in index_*
c    narrow_band(in):   array that marks voxels outside desired fillbox
c    mark_fb(in):       upper limit narrow band value for voxels in 
c                       fillbox
c    *_gb (in):         index range for ghostbox
c
c***********************************************************************
      subroutine lsm2dComputeAveGradPhiLOCAL(
     &  grad_phi_ave, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  jlo_phi_gb, jhi_phi_gb,
     &  dx, dy,
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

      double precision grad_phi_ave
      integer ilo_phi_gb, ihi_phi_gb
      integer jlo_phi_gb, jhi_phi_gb
      double precision phi(ilo_phi_gb:ihi_phi_gb,
     &                     jlo_phi_gb:jhi_phi_gb)
      double precision dx, dy
      integer nlo_index, nhi_index
      integer index_x(nlo_index:nhi_index)
      integer index_y(nlo_index:nhi_index)
      integer ilo_nb_gb, ihi_nb_gb
      integer jlo_nb_gb, jhi_nb_gb
      integer*1 narrow_band(ilo_nb_gb:ihi_nb_gb,
     &                      jlo_nb_gb:jhi_nb_gb)
      integer*1 mark_fb

c     local variables      
      integer i,j,l,count
      double precision dx_factor, dy_factor
      double precision phi_x, phi_y
      

c     compute denominator values
      dx_factor = 0.5d0/dx
      dy_factor = 0.5d0/dy

      grad_phi_ave = 0.d0
      count = 0
c     { begin loop over indexed points
      do l= nlo_index, nhi_index      
        i=index_x(l)
	j=index_y(l)

c       include only fill box points (marked appropriately)
        if( narrow_band(i,j) .le. mark_fb ) then
      
          phi_x = (phi(i+1,j) - phi(i-1,j))*dx_factor
          phi_y = (phi(i,j+1) - phi(i,j-1))*dy_factor
	
	  grad_phi_ave = grad_phi_ave + sqrt(phi_x*phi_x + phi_y*phi_y) 
	  count = count + 1
        endif
      enddo
c     } end loop over indexed points
 
      if ( count .gt. 0 ) then
        grad_phi_ave = grad_phi_ave / (count)
      endif

      return
      end
c } end subroutine
c***********************************************************************