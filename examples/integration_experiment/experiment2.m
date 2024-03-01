%%
x_exact = [-0.499652437602126;-0.018639783973257];
stage_counts = [5, 10, 20, 40, 70, 100, 200];% 5000, 10000];
n_s_list = [1,2,3,4];
N_fe = 2;
T = 5;

comp_tol = 1e-12;

% do no FESD runs
no_fesd_all_hs = {};
no_fesd_all_errors = {};
no_fesd_all_errors_max = {};
for n_s=n_s_list
    no_fesd_errors = [];
    no_fesd_errors_max = [];
    no_fesd_hs = [];
    for N_sim=stage_counts
        [prob, data, opts, h] = integrator_circular_c(T, N_sim, N_fe, false, n_s);
        orig_init = prob.w.init;
        %% S I M U L A T E
        x_curr = data.x0;
        lambda_curr = 0;
        for step=1:N_sim
            prob.w.init = orig_init;
            prob.w.x(0,0,data.n_s).init = x_curr;
            prob.w.x(0,0,data.n_s).lb = x_curr;
            prob.w.x(0,0,data.n_s).ub = x_curr;
            prob.w.lambda(0,0,data.n_s).init = lambda_curr;
            prob.w.lambda(0,0,data.n_s).lb = lambda_curr;
            prob.w.lambda(0,0,data.n_s).ub = lambda_curr;
            [success,stats] = homotopy(prob, 1, comp_tol);
            disp(['step=' num2str(step) ' n_s=' num2str(n_s) ' N_sim=' num2str(N_sim) ' Standard'])
            x_curr = prob.w.x(1,data.N_fe,data.n_s).res;
            lambda_curr = prob.w.lambda(1,data.N_fe,data.n_s).res;
        end
        error = norm(x_curr - x_exact);
        max_error = max(abs(x_curr - x_exact));
        no_fesd_hs = [no_fesd_hs;h];
        no_fesd_errors = [no_fesd_errors;error];
        no_fesd_errors_max = [no_fesd_errors_max;max_error];
    end
    no_fesd_all_hs{n_s} = no_fesd_hs;
    no_fesd_all_errors{n_s} = no_fesd_errors;
    no_fesd_all_errors_max{n_s} = no_fesd_errors_max;
end

% do FESD runs
fesd_all_hs = {};
fesd_all_errors = {};
fesd_all_errors_max = {};
for n_s=n_s_list
    fesd_errors = [];
    fesd_errors_max = [];
    fesd_hs = [];
    for N_sim=stage_counts
        [prob, data, opts, h] = integrator_circular_c(T, N_sim, N_fe, true, n_s);
        orig_init = prob.w.init;
        %% S I M U L A T E
        x_curr = data.x0;
        lambda_curr = 0;
        for step=1:N_sim
            prob.w.init = orig_init;
            prob.w.x(0,0,data.n_s).init = x_curr;
            prob.w.x(0,0,data.n_s).lb = x_curr;
            prob.w.x(0,0,data.n_s).ub = x_curr;
            prob.w.lambda(0,0,data.n_s).init = lambda_curr;
            prob.w.lambda(0,0,data.n_s).lb = lambda_curr;
            prob.w.lambda(0,0,data.n_s).ub = lambda_curr;
            [success,stats] = homotopy(prob, 1, comp_tol);
            disp(['step=' num2str(step) ' n_s=' num2str(n_s) ' N_sim=' num2str(N_sim) ' FESD'])
            x_curr = prob.w.x(1,data.N_fe,data.n_s).res;
            lambda_curr = prob.w.lambda(1,data.N_fe,data.n_s).res;
        end
        error = norm(x_curr - x_exact);
        max_error = max(abs(x_curr - x_exact));
        fesd_hs = [fesd_hs;h];
        fesd_errors = [fesd_errors;error];
        fesd_errors_max = [fesd_errors_max;max_error];
    end
    fesd_all_hs{n_s} = fesd_hs;
    fesd_all_errors{n_s} = fesd_errors;
    fesd_all_errors_max{n_s} = fesd_errors_max;
end
%% save vars
save(['order_data_' char(datetime('now', 'format', 'yyyyMMddHHmmSS')) '.mat'],'fesd_all_hs','fesd_all_errors','no_fesd_all_hs','no_fesd_all_errors')
%% plot
figure('Position', [10 10 800 600])
hold on;
for n_s=n_s_list
    plot(no_fesd_all_hs{n_s},no_fesd_all_errors{n_s}, '-x', 'Markersize', 20.0, 'Linewidth', 5.0, 'DisplayName', sprintf('$n_s=%d$', n_s));
end
set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
xlabel('$|h_0|$', 'fontsize', 64)
ylabel('$\mathrm{error}$', 'fontsize', 64)
legend('location', 'southeast', 'fontsize', 42)
ylim([0.9e-14,1])
hold off
ax = gca;
ax.XAxis.FontSize = 56;
ax.YAxis.FontSize = 56;
grid on
exportgraphics(gca, '~/syscop/cdc2024_fesd_pds/figures/rk_pds_order_plot_2.pdf')

figure('Position', [10 10 800 600])
hold on;
for n_s=n_s_list
    plot(fesd_all_hs{n_s},fesd_all_errors{n_s}, '-x', 'Markersize', 20.0, 'Linewidth', 5.0, 'DisplayName', sprintf('$n_s=%d$', n_s));
end
set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
xlabel('$|h_0|$', 'fontsize', 64)
ylabel('$\mathrm{error}$', 'fontsize', 64)
legend('location', 'southeast', 'fontsize', 42)
ylim([0.9e-14,1])
hold off
ax = gca;
ax.XAxis.FontSize = 56;
ax.YAxis.FontSize = 56;
grid on
exportgraphics(gca, '~/syscop/cdc2024_fesd_pds/figures/fesd_pds_order_plot_2.pdf')


figure
hold on;
for n_s=n_s_list
    plot(no_fesd_all_hs{n_s},no_fesd_all_errors_max{n_s}, '-x', 'Markersize', 20.0, 'Linewidth', 5.0, 'DisplayName', sprintf('$n_s=%d$', n_s));
end
set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
xlabel('$|h_0|$')
ylabel('$\mathrm{error}$')
title('$\ell_\infty$ error RK')
legend('location', 'southeast')
ylim([0.9e-14,1])
hold off


figure
hold on;
for n_s=n_s_list
    plot(fesd_all_hs{n_s},fesd_all_errors_max{n_s}, '-x', 'Markersize', 20.0, 'Linewidth', 5.0, 'DisplayName', sprintf(' $n_s=%d$', n_s));
end
set(gca, 'XScale', 'log')
set(gca, 'YScale', 'log')
xlabel('$|h_0|$')
ylabel('$\mathrm{error}$')
title('$\ell_\infty$ error FESD')
legend('location', 'southeast')
ylim([0.9e-14,1])
hold off
