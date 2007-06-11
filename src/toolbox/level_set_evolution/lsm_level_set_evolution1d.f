c***********************************************************************
c
c  File:        lsm_level_set_evolution1d.f
c  Copyright:   (c) 2005-2006 Kevin T. Chu
c  Revision:    $Revision: 1.3 $
c  Modified:    $Date: 2006/01/24 21:46:40 $
c  Description: F77 subroutines for 1D level set evolution equation 
c
c***********************************************************************

c***********************************************************************
c
c  lsm1dZeroOutLevelSetEqnRHS() zeros out the right-hand side of the
c  level set equation when it is written in the form:
c
c    phi_t = ...
c
c  Arguments:
c    lse_rhs (in/out):  right-hand of level set equation
c    *_gb (in):         index range for ghostbox
c
c***********************************************************************
      subroutine lsm1dZeroOutLevelSetEqnRHS(
     &  lse_rhs,
     &  ilo_lse_rhs_gb, ihi_lse_rhs_gb)
c***********************************************************************
c { begin subroutine
      implicit none

      integer ilo_lse_rhs_gb, ihi_lse_rhs_gb
      double precision lse_rhs(ilo_lse_rhs_gb:ihi_lse_rhs_gb)
      integer i

c     { begin loop over grid
      do i=ilo_lse_rhs_gb,ihi_lse_rhs_gb
        
        lse_rhs(i) = 0.d0
      
      enddo 
c     } end loop over grid

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dAddAdvectionTermToLSERHS adds the contribution of an advection
c  term (external vector velocity field) to the right-hand side of the 
c  level set equation when it is written in the form:
c
c    phi_t = -vel dot grad(phi) + ...
c
c  Arguments:
c    lse_rhs (in/out):  right-hand of level set equation
c    phi_* (in):        components of grad(phi) at t = t_cur
c    vel_* (in):        components of velocity at t = t_cur
c    *_gb (in):         index range for ghostbox
c    *_fb (in):         index range for fillbox
c
c***********************************************************************
      subroutine lsm1dAddAdvectionTermToLSERHS(
     &  lse_rhs,
     &  ilo_lse_rhs_gb, ihi_lse_rhs_gb,
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb,
     &  vel_x,
     &  ilo_vel_gb, ihi_vel_gb,
     &  ilo_fb, ihi_fb)
c***********************************************************************
c { begin subroutine
      implicit none

      integer ilo_lse_rhs_gb, ihi_lse_rhs_gb
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_fb, ihi_fb
      double precision lse_rhs(ilo_lse_rhs_gb:ihi_lse_rhs_gb)
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision vel_x(ilo_vel_gb:ihi_vel_gb)
      integer i

c     { begin loop over grid
      do i=ilo_fb,ihi_fb
        
        lse_rhs(i) = lse_rhs(i) - vel_x(i)*phi_x(i)
      
      enddo 
c     } end loop over grid

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dAddNormalVelTermToLSERHS() adds the contribution of a normal 
c  (scalar) velocity term to the right-hand side of the level set 
c  equation when it is written in the form:
c
c    phi_t = -V_n |grad(phi)| + ...
c
c  Arguments:
c    lse_rhs (in/out):  right-hand of level set equation
c    phi_*_plus (in):   components of forward approx to grad(phi) at 
c                       t = t_cur
c    phi_*_minus (in):  components of backward approx to grad(phi) at 
c                       t = t_cur
c    vel_n (in):        normal velocity at t = t_cur
c    *_gb (in):         index range for ghostbox
c    *_fb (in):         index range for fillbox
c
c***********************************************************************
      subroutine lsm1dAddNormalVelTermToLSERHS(
     &  lse_rhs,
     &  ilo_lse_rhs_gb, ihi_lse_rhs_gb,
     &  phi_x_plus, 
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  phi_x_minus, 
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  vel_n,
     &  ilo_vel_gb, ihi_vel_gb,
     &  ilo_fb, ihi_fb)
c***********************************************************************
c { begin subroutine
      implicit none

      integer ilo_lse_rhs_gb, ihi_lse_rhs_gb
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_fb, ihi_fb
      double precision lse_rhs(ilo_lse_rhs_gb:ihi_lse_rhs_gb)
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      double precision vel_n(ilo_vel_gb:ihi_vel_gb)
      integer i
      double precision vel_n_cur
      double precision phi_x_sq_cur
      double precision tol
      parameter (tol=1.d-13)

c     { begin loop over grid
      do i=ilo_fb,ihi_fb

        vel_n_cur = vel_n(i)

c       { begin Godunov selection of grad_phi

        if (vel_n_cur .gt. 0.d0) then
          phi_x_sq_cur = max(max(phi_x_minus(i),0.d0)**2,
     &                       min(phi_x_plus(i),0.d0)**2 )
        else
          phi_x_sq_cur = max(min(phi_x_minus(i),0.d0)**2,
     &                       max(phi_x_plus(i),0.d0)**2 )
        endif
c       } end Godunov selection of grad_phi


c       compute contribution to lse_rhs(i) 
        if (abs(vel_n_cur) .ge. tol) then
          lse_rhs(i) = lse_rhs(i) - vel_n_cur*sqrt(phi_x_sq_cur)
        endif
      
      enddo 
c     } end loop over grid

      return
      end
c } end subroutine
c***********************************************************************