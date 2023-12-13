module veriWakePort (
    input reset,  /* Pulso de reset ativo em nivel HIGH, para configurar o horÃ¡rio para a hora e minuto de entrada (definidos pelas entradas H_in1, H_in0, M_in1 e M_in0) e os segundos para 00. Deve tambÃ©m definir o valor do alarme para 0.00.00 e o Alarme (saida) em nivel LOW. Para Operacao normal, este pino de entrada deve ser 0.*/
    input clk,  /* Um clock de entrada de 10Hz. Deve ser usado para gerar cada segundo em tempo real. */
    input [1:0] H_in1, /* Uma entrada de 2 bits usada para definir o digito mais significativo da hora do relogio (se LD_time=1), ou o digito mais significativo da hora do alarme (se LD_alarm=1). Valores validos sao de 0 a 2. */ 
    input [3:0] H_in0, /* Uma entrada de 4 bits usada para definir o digito menos significativo da hora do relogio (se LD_time=1), ou o digito menos significativo da hora do alarme (se LD_alarm=1). Valores validos sao de 0 a 9. */
    input [3:0] M_in1, /* Uma entrada de 4 bits usada para definir o digito mais significativo do minuto do relogio (se LD_time=1), ou o digito mais significativo do minuto do alarme (se LD_alarm=1). Valores validos sao de 0 a 5. */
    input [3:0] M_in0, /* Uma entrada de 4 bits usada para definir o digito menos significativo do minuto do relogio (se LD_time=1), ou o digito menos significativo do minuto do alarme (se LD_alarm=1). Valores validos sao de 0 a 9. */
    input LD_time,  /* Se LD_time=1, o tempo deve ser configurado com os valores nas entradas H_in1, H_in0, M_in1 e M_in0. Os segundos devem ser configurados para 0. Se LD_time=0, o relogio deve operar normalmente (ou seja, os segundos devem ser incrementados a cada 10 ciclos de clock). */
    input LD_alarm,  /* Se LD_alarm=1, o tempo do alarme deve ser configurado com os valores nas entradas H_in1, H_in0, M_in1 e M_in0. Se LD_alarm=0, o relogio deve operar normalmente. */ 
    input STOP_al,  /* Se o Alarme (saida) estiver HIGH, entao STOP_al=1 trara a saida de volta para LOW. */ 
    input AL_ON,  /* Se HIGH, o alarme estao LIGADO (e o Alarme ficarÃ¡ HIGH se o tempo do alarme for igual ao tempo real). Se LOW, a Funcao de alarme estao DESLIGADA. */
    input count,
	 output reg Alarm,  /* Isso ficarÃ¡ HIGH se o tempo do alarme for igual ao tempo atual e AL_ON estiver HIGH. Isso permanecerÃ¡ HIGH atÃ© que STOP_al seja HIGH, o que trara o Alarme de volta para LOW. */
    output [1:0]  H_out1, 
    /* O digito mais significativo da hora. Valores validos sao de 0 a 2. */
    output [3:0]  H_out0, 
    /* O digito menos significativo da hora. Valores validos sao de 0 a 9. */
    output [3:0]  M_out1, 
    /* O digito mais significativo do minuto. Valores validos sao de 0 a 5. */
    output [3:0]  M_out0, /* O digito menos significativo do minuto. Valores validos sao de 0 a 9. */
    output [3:0]  S_out1, /* O digito mais significativo do segundo. Valores validos sao de 0 a 5. */
    output [3:0]  S_out0  /* O digito menos significativo do segundo. Valores validos sao de 0 a 9. */
);

// Sinal interno
reg clk_1s; // Clock de 1 segundo
reg [3:0] tmp_1s; // Contador para criar o clock de 1 segundo 
reg [5:0] tmp_hour, tmp_minute, tmp_second; 
// Contador para horas, minutos e segundos do relogio
reg [1:0] c_hour1,a_hour1; 
/* O digito mais significativo da hora do relogio e do alarme. */ 
reg [3:0] c_hour0,a_hour0;
/* O digito menos significativo da hora do relogio e do alarme. */ 
reg [3:0] c_min1,a_min1;
/* O digito mais significativo do minuto do relogio e do alarme.*/ 
reg [3:0] c_min0,a_min0;
/* O digito menos significativo do minuto do relogio e do alarme.*/ 
reg [3:0] c_sec1,a_sec1;
/* O digito mais significativo do segundo do relogio e do alarme.*/ 
reg [3:0] c_sec0,a_sec0;
/* O digito menos significativo do segundo do relogio e do alarme.*/ 

/************************************************/ 
/****************Funcao mod10*****************/
/*************************************************/ 
function [3:0] mod_10;
input [5:0] number;
begin
    mod_10 = (number >=50) ? 5 : ((number >= 40)? 4 :((number >= 30)? 3 :((number >= 20)? 2 :((number >= 10)? 1 :0))));
end
endfunction

/*************************************************/ 
/************* Operacao do relogio**************/
/*************************************************/ 
always @(posedge clk_1s or posedge reset )
begin
    if(reset) begin // Reset HIGH => tempo do alarme para 00.00.00, alarme para LOW, relogio para H_in e M_in e S para 00
        a_hour1 <= 2'b00;
        a_hour0 <= 4'b0000;
        a_min1 <= 4'b0000;
        a_min0 <= 4'b0000;
        a_sec1 <= 4'b0000;
        a_sec0 <= 4'b0000;
        tmp_hour <= H_in1*10 + H_in0;
        tmp_minute <= M_in1*10 + M_in0;
        tmp_second <= 0;
    end 
    else begin
        if(LD_alarm) begin // LD_alarm =1 => ajustar o relogio do alarme para H_in, M_in
            a_hour1 <= H_in1;
            a_hour0 <= H_in0;
            a_min1 <= M_in1;
            a_min0 <= M_in0;
            a_sec1 <= 4'b0000; // segundos do alarme para 00
            a_sec0 <= 4'b0000; // segundos do alarme para 00
        end 
        if(LD_time) begin // LD_time =1 => ajustar o tempo para H_in, M_in
            tmp_hour <= H_in1*10 + H_in0;
            tmp_minute <= M_in1*10 + M_in0;
            tmp_second <= 0;
        end 
        else begin  // LD_time =0 , relogio opera normalmente
            tmp_second <= tmp_second + 1;
            if(tmp_second >=59) begin // segundo > 59 entao aumenta o minuto
                tmp_minute <= tmp_minute + 1;
                tmp_second <= 0;
                if(tmp_minute >=59) begin // minuto > 59 entao aumenta a hora
                    tmp_minute <= 0;
                    tmp_hour <= tmp_hour + 1;
                    if(tmp_hour >= 24) begin // hora > 24 entao ajustar hora para 0
                        tmp_hour <= 0;
                    end 
                end 
            end
        end 
    end 
end 


/*************************************************/ 
/******** Criar clock de 1 segundo****************/
/*************************************************/ 
always @(posedge clk or posedge reset)
begin
    if(reset) 
    begin
        tmp_1s <= 0;
        clk_1s <= 0;
    end
    else begin
        tmp_1s <= tmp_1s + 1;
        if(tmp_1s <= 5) 
            clk_1s <= 0;
        else if (tmp_1s >= 10) begin
            clk_1s <= 1;
            tmp_1s <= 1;
        end
        else
            clk_1s <= 1;
    end
end

/*************************************************/ 
/**SAIDA DO RELOGIO*********************/ 
/*************************************************/ 
always @(*) begin

    if(tmp_hour>=20) begin
        c_hour1 = 2;
    end
    else begin
        if(tmp_hour >=10) 
            c_hour1  = 1;
        else
            c_hour1 = 0;
    end
    c_hour0 = tmp_hour - c_hour1*10; 
    c_min1 = mod_10(tmp_minute); 
    c_min0 = tmp_minute - c_min1*10;
    c_sec1 = mod_10(tmp_second);
    c_sec0 = tmp_second - c_sec1*10; 
end
assign H_out1 = c_hour1; // digito mais significativo da hora do relogio
assign H_out0 = c_hour0; // digito menos significativo da hora do relogio
assign M_out1 = c_min1; // digito mais significativo do minuto do relogio
assign M_out0 = c_min0; // digito menos significativo do minuto do relogio
assign S_out1 = c_sec1; // digito mais significativo do segundo do relogio
assign S_out0 = c_sec0; // digito menos significativo do segundo do relogio 

/*************************************************/ 
/******** Funcao do alarme******************/
/*************************************************/ 
always @(posedge clk_1s or posedge reset) begin
    if(reset) 
        Alarm <=0; 
    else begin
        if({a_hour1,a_hour0,a_min1,a_min0,a_sec1,a_sec0}=={c_hour1,c_hour0,c_min1,c_min0,c_sec1,c_sec0})
        begin // se o tempo do alarme for igual ao tempo do relogio, pulsarÃ¡ o sinal de Alarme HIGH com AL_ON=1
            if(AL_ON) Alarm <= 1; // variavel Alarm ativada (colocar como acionamento do motor)
        end
        if(STOP_al) Alarm <=0; // quando STOP_al = 1, levarÃ¡ o sinal de Alarme para LOW
    end
end

endmodule