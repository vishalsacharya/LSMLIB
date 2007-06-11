%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TVD_RK3_STAGE1 advances the solution through the first stage of a 
%                third-order TVD Runge-Kutta step.
%
% Usage: u_stage1 = TVD_RK3_STAGE1(u_cur, rhs, dt)
%
% Arguments:
% - u_cur:       u(t_cur)
% - rhs:         right-hand side of time evolution equation at t_cur
% - dt:          step size
%
% Return value:
% - u_stage1:    u_approx(t_cur + dt)
%
% NOTES:
% - u_cur and rhs are assumed to have the same dimensions.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author:     Kevin T. Chu 
% Copyright:  (c) 2005-2006, MAE Princeton University 
% Revision:   $Revision: 1.3 $
% Modified:   $Date: 2006/04/22 12:39:34 $
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function u_stage1 = TVD_RK3_STAGE1(u_cur, rhs, dt)

u_stage1 = u_cur + dt*rhs;