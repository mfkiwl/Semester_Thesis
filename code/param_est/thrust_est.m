clc
clear 
close all

%% Constants

Ts = 1/500;                      % Sample time of the controller 
Fs = 1/Ts;
T = 0.0617;                      % Time constant T [s] of the actuator
alpha = 1 - exp(-Ts/T);   

filename = "csv_data/log_thrust_est_2.csv";

%% Data import

[tick, gyro_roll, gyro_pitch, gyro_yaw, cmd_thrust, cmd_roll,... 
 cmd_pitch, cmd_yaw, accelz] = import_logdata(filename);


%% Computation
start_samp = 2000;
end_samp = 11000;                               % Number of samples to consider
accelz = accelz(start_samp:end_samp)*9.81;      % Specific force F/m in [m/s^2]
cmd_thrust = cmd_thrust(start_samp:end_samp);   % Thrust command € [0, 60000]

% Pass cmd through the actuator dynamics
cmd_thrust_a = filter([alpha], [1, -(1-alpha)], cmd_thrust, cmd_thrust(1)*(1-alpha));


% Differentiate both signals to get rid of the offset
d_accelz = diff(accelz)/Ts;
d_cmd_thrust_a = diff(cmd_thrust_a)/Ts;

% Filter derivatives to remove noise for better fitting
[b, a] = butter(2, 8/(Fs/2));                   % compute filter coeffs
d_accelz = filter(b, a, d_accelz);
d_cmd_thrust_a = filter(b, a, d_cmd_thrust_a);

% Compute parameter K with least squares
K_cmd = d_cmd_thrust_a \ d_accelz


%% Plotting

% % Specific force
% fig1 = figure('Name', 'Specifc force');
% plot(accelz); hold on; grid on;
% xlim([0 inf])

% % Thrust command 
% fig2 = figure('Name', 'Thrust cmd');
% plot(cmd_thrust); grid on; hold on;
% plot(cmd_thrust_a)
% legend('original', 'actuator')
% xlim([0 inf])

% Results derivatives
fig3 = figure('Name', 'Results derivatives')
subplot(2, 1, 1)
plot(d_accelz); hold on;
plot(d_cmd_thrust_a * K_cmd);
xlim([0 inf]); grid on;
xlabel('Samples $$[-]$$', 'Interpreter', 'latex')
ylabel('$$[m/s^3]$$', 'Interpreter', 'latex')
legend('$$\ddot{v}_{z}$$', '$$ \dot{T}_{cmd, a} \cdot K_{cmd} $$', 'Interpreter', 'latex', 'Location', 'southeast');

% Results original value
%fig4 = figure('Name', 'Results original values')
subplot(2, 1, 2)
plot(accelz); hold on;
plot(cmd_thrust_a * K_cmd);
xlim([0 inf]); grid on;
xlabel('Samples $$[-]$$', 'Interpreter', 'latex')
ylabel('$$[m/s^2]$$', 'Interpreter', 'latex')
legend('$$\dot{v}_{z}$$', '$$ T_{cmd, a} \cdot K_{cmd} $$', 'Interpreter', 'latex', 'Location', 'southeast');


%% Saving plots
set(fig3, 'Units', 'points');
pos = get(fig3, 'Position');                        % gives x left, y bottom, width, height
width = pos(3);
height = pos(4);
set(fig3, 'PaperUnits', 'points');
set(fig3, 'PaperPosition', [0 0 width height]);     % Position plot at left hand corner with width 5 and height 5.
set(fig3, 'PaperSize', [width height]);             % Set the paper to have width 5 and height 5.
saveas(fig3, 'thrust_mapping', 'pdf');                       % Save figure


