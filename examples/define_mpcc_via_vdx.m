%% MPCC Example via VDX
% this examples uses VDX to define a generic MPCC (cf. https://github.com/apozharski/vdx)
% VDX is a tool that facilitates index tracking and result extraction when formulating optimization problems with CasADi.

close all;
clear all;
import casadi.*;
import nosnoc.solver.mpccsol;

opts = nosnoc.solver.Options();
mpccsol_opts.relaxation = opts;
mpcc = vdx.problems.Mpcc();

x = SX.sym('x', 2);
mpcc.w.x(0) = {x,0, inf};
mpcc.f = norm(x- [-1;0])^2;
mpcc.G.x(0) = {x(1)};
mpcc.H.x(0) = {x(2)};

mpcc_struct = mpcc.to_casadi_struct;

solver = mpccsol('generic_mpcc', 'relaxation', mpcc_struct, mpccsol_opts);

mpcc_results = solver('x0', mpcc.w.init,...
    'lbx', mpcc.w.lb,...
    'ubx', mpcc.w.ub);

