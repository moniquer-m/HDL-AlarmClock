module veriWake;
 // Entradas
 reg reset;
 reg clk;
 reg [1:0] H_in1;
 reg [3:0] H_in0;
 reg [3:0] M_in1;
 reg [3:0] M_in0;
 reg LD_time;
 reg LD_alarm;
 reg STOP_al;
 reg AL_ON;
 integer count;

 // Saidas
 wire Alarm;
 wire [1:0] H_out1;
 wire [3:0] H_out0;
 wire [3:0] M_out1;
 wire [3:0] M_out0;
 wire [3:0] S_out1;
 wire [3:0] S_out0;
 // Instanciar a Unidade Sob Teste (UUT)
 veriWakePort uut (
 .reset(reset), 
 .clk(clk), 
 .H_in1(H_in1), 
 .H_in0(H_in0), 
 .M_in1(M_in1), 
 .M_in0(M_in0), 
 .LD_time(LD_time), 
 .LD_alarm(LD_alarm), 
 .STOP_al(STOP_al), 
 .AL_ON(AL_ON), 
 .Alarm(Alarm), 
 .H_out1(H_out1), 
 .H_out0(H_out0), 
 .M_out1(M_out1), 
 .M_out0(M_out0), 
 .S_out1(S_out1), 
 .S_out0(S_out0),
 .count(count)
 );

 initial begin
 // Inicializar as Entradas
 reset = 1;
 H_in1 = 1;
 H_in0 = 0;
 M_in1 = 1;
 M_in0 = 4;
 LD_time = 0;
 LD_alarm = 0;
 STOP_al = 0;
 AL_ON = 0; // ajustar horario do relogio para 11h26, tempo do alarme para 00h00 durante o reset
 // Aguardar 1000 ns para o reset global terminar
 #1000;
      reset = 0;
 H_in1 = 1;
 H_in0 = 0;
 M_in1 = 2;
 M_in0 = 0;
 LD_time = 0;
 LD_alarm = 1;
 STOP_al = 0;
 AL_ON = 1; // ligar o Alarme e definir o tempo do alarme para 11h30
 #1000; 
 reset = 0;
 H_in1 = 1;
 H_in0 = 0;
 M_in1 = 2;
 M_in0 = 0;
 LD_time = 0;
 LD_alarm = 0;
 STOP_al = 0;
 AL_ON = 1; 
 wait(Alarm); // aguardar atÃƒÂ© que o sinal de Alarme esteja HIGH quando o tempo do alarme for igual ao tempo do relogio
 #1000
 STOP_al = 1; // pulsar HIGH o STOP_al para levar o sinal de Alarme para LOW
 #1000
 STOP_al = 0;
 H_in1 = 0;
 H_in0 = 4;
 M_in1 = 4;
 M_in0 = 5;
 LD_time = 1; // ajustar horario do relogio para 11h25
 LD_alarm = 0;
 #1000
 STOP_al = 0;
 H_in1 = 0;
 H_in0 = 4;
 M_in1 = 5;
 M_in0 = 5;
 LD_alarm = 1; // ajustar tempo do alarme para 11h35
 LD_time = 0;
 wait(Alarm); // aguardar atÃƒÂ© que o sinal de Alarme esteja HIGH quando o tempo do alarme for igual ao tempo do relogio
 #1000
 STOP_al = 1;// pulsar HIGH o STOP_al para levar o sinal de Alarme para LOW
 end
  // Clock
initial begin
  clk = 0;
  count = 0;
  repeat (50000) begin
    #50 clk = ~clk;
    count = count + 1;
  end
  $stop;
end
endmodule