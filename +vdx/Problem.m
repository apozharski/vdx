classdef Problem < handle &...
        matlab.mixin.Copyable
% A class represnting an NLP in the form:
% TODO(@anton) figure out how to write the NLP in docs in a nice way
%
%:param string casadi_type: either 'SX' (default) or 'MX' which determines the kind of CasADi symbolics uesd for all :class:`vdx.Vector`.
%:ivar obj.w.x: This is a test
    properties (Access=public)
        % Primal variabiles
        %
        %:type: vdx.PrimalVector
        w vdx.PrimalVector
        
        % Constraints
        %
        %:type: vdx.ConstraintVector
        g vdx.ConstraintVector
        
        % Parameters
        %
        %:type: vdx.ParameterVector
        p vdx.ParameterVector
        
        % Objective
        %
        %:type: casadi.SX|casadi.MX
        f
        
        % Objective value
        %
        %:type: double
        f_result (1,1) double

        % Solver name
        %
        %:type: char
        solver_name (1,:) char
    end
    properties (Access=public, NonCopyable)
        % CasADi `nlpsol` object for the given problem.
        % generated by :meth:`create_solver` and is `[]` before the first time it is called.
        solver
    end

    methods (Access=public)
        function obj = Problem(varargin)
            p = inputParser;
            addParameter(p, 'casadi_type', 'SX');
            addParameter(p, 'solver_name', 'vdx_problem_solver');
            parse(p, varargin{:});
            
            obj.w = vdx.PrimalVector(obj, 'casadi_type', p.Results.casadi_type);
            obj.g = vdx.ConstraintVector(obj, 'casadi_type', p.Results.casadi_type);
            obj.p = vdx.ParameterVector(obj, 'casadi_type', p.Results.casadi_type);
            obj.f = 0;
            obj.f_result = 0;

            obj.solver_name = p.Results.solver_name;
        end

        function create_solver(obj, casadi_options, plugin)
        % Creates the CasADi nlpsol object based on the current symbolics in :attr:`w`, :attr:`g`, :attr:`p`, and :attr:`f`.
        %
        %:param struct casadi_options: Options passed to `casadi.nlpsol` TODO(@anton) link to CasADi docs here.
        %:param char plugin: `casadi.nlpsol` plugin to use.
            if ~exist('plugin')
                plugin = 'ipopt';
            end
            
            obj.finalize_assignments()

            casadi_nlp = obj.to_casadi_struct();
            obj.solver = casadi.nlpsol(obj.solver_name, plugin, casadi_nlp, casadi_options);
        end

        function [stats, nlp_results] = solve(obj)
        % Solves the NLP with the data currently in :attr:`w`, :attr:`g`, :attr:`p`.
        % Populates the results and Lagrange multipliers fielts of the same. TODO(@anton) figure out how to link attrs of other classes
        %
        %:returns: Stats and nlp_results.
            nlp_results = obj.solver('x0', obj.w.init,...
                'lbx', obj.w.lb,...
                'ubx', obj.w.ub,...
                'lbg', obj.g.lb,...
                'ubg', obj.g.ub,...
                'lam_g0', obj.g.init_mult,...% TODO(@anton) perhaps we use init instead of mult.
                'lam_x0', obj.w.init_mult,...
                'p', obj.p.val);
            if ~obj.solver.stats.success
                %warning("failed to converge")
            end
            obj.w.res = full(nlp_results.x);
            obj.w.mult = full(nlp_results.lam_x);
            obj.g.eval = full(nlp_results.g);
            obj.g.mult = full(nlp_results.lam_g);
            obj.p.mult = full(nlp_results.lam_p);
            obj.f_result = full(nlp_results.f);

            % Calculate violations:
            w_lb_viol = max(obj.w.lb - obj.w.res, 0);
            w_ub_viol = max(obj.w.res - obj.w.ub, 0);
            obj.w.violation = max(w_lb_viol, w_ub_viol);
            g_lb_viol = max(obj.g.lb - obj.g.eval, 0);
            g_ub_viol = max(obj.g.eval - obj.g.ub, 0);
            obj.g.violation = max(g_lb_viol, g_ub_viol);
            
            stats = obj.solver.stats;
        end

        function mpcc_struct = to_casadi_struct(obj)
            mpcc_struct = struct;
            mpcc_struct.x = obj.w.sym;
            mpcc_struct.g = obj.g.sym;
            mpcc_struct.p = obj.p.sym;
            mpcc_struct.f = obj.f;
        end

        function print(obj, varargin)
            w_out = obj.w.to_string(varargin{:});
            p_out = obj.p.to_string(varargin{:});
            g_out = obj.g.to_string(varargin{:});

            n_longest = max([longest_line(w_out), longest_line(p_out), longest_line(g_out)]);

            hline(1:n_longest) = '-';
            hline = [hline '\n'];
            
            fprintf(hline);
            fprintf("Primal Variables\n");
            fprintf(hline);
            fprintf(w_out);
            fprintf(hline);
            fprintf("Parameters\n");
            fprintf(hline);
            fprintf(p_out);
            fprintf(hline);
            fprintf("Constraints\n");
            fprintf(hline);
            fprintf(g_out);
            fprintf(hline);
            fprintf("Objective\n");
            fprintf(hline);
            print_casadi_vector(obj.f);
        end

        function finalize_assignments(obj)
            obj.w.apply_queued_assignments;
            obj.g.apply_queued_assignments;
            obj.p.apply_queued_assignments;
        end
    end
    
    methods (Access=protected)
        function cp = copyElement(obj)
            cp = copyElement@matlab.mixin.Copyable(obj);

            cp.w = copy(obj.w);
            cp.w.problem = cp;
            cp.g = copy(obj.g);
            cp.g.problem = cp;
            cp.p = copy(obj.p);
            cp.p.problem = cp;
            cp.f = obj.f;
        end
    end
end
