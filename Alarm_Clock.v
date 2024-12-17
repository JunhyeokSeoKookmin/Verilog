`timescale 1ns / 1ps

// --------------------------------------
//
//          Alarm Clock
//          
//
// --------------------------------------




//================================== main up module =======================================
module Alarm_Clock(clk,upButton,downButton,switchBetweenSwitch, resetButton,reset3bitCounterSW , reset1HzclkSW,enableAlarmSW,      Alarm_seconds, Alarm_minutes , AN,CX ,AlarmLED, AlarmOutputLED);
    input clk;
    input upButton;
    input downButton;
    input switchBetweenSwitch;     
    input resetButton;  
    input reset3bitCounterSW;               //always == 1
    input reset1HzclkSW;                    //reset the 1 Hz clock --> this is gonna reset the digital clock
    input enableAlarmSW;
    
    output [5:0] Alarm_seconds, Alarm_minutes;
    wire [5:0] Clock_seconds, Clock_minutes;
    wire [2:0]Q;                            //counter outputs = selecters
    wire [3:0] upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1,upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0;
    output [7:0]AN;
    output [7:0]CX;
    output reg AlarmLED;
    output reg AlarmOutputLED;
    
   
    //--------------------- all clocks needed
    slowerClkGen1Hz    clk1Hz   (clk, reset1HzclkSW, clk1HzOutsignal );      //slow
    slowerClkGen10Hz   clk10Hz  (clk, reset10HzclkSW, clk10HzOutsignal);     
    slowerClkGen400Hz  clk400Hz (clk, reset400HzclkSW, clk400HzOutsignal);   //fast
    
    
    //---------------------- the 2 counters: alarm and digital clock
    upandDownCounter stage1 (clk10HzOutsignal, upButton,downButton ,switchBetweenSwitch, resetButton   ,Alarm_seconds, Alarm_minutes  );   //done
    min_sec_counters stage2 (clk1HzOutsignal,  Clock_seconds, Clock_minutes);
    
    
    //---------------------- separate the digits
    digitsSeparator stage3 (Clock_seconds, Clock_minutes,  upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0);    
    digitsSeparator stage4 (Alarm_seconds, Alarm_minutes,  upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1);
    
    //---------------------- display the all the digits on the 7-segments displays    
    counter3bit sub3bitCounter (1'b1, clk400HzOutsignal, 1'b1, Q);     //3-bit counter to run through all 8 7-segemnts displays really fast using the 400Hz clk Selecters
    mux8to1     stage5 (Q, upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0,upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1,        AN, CX);
    
    
  
    
    reg alarmTriggered;                                                              //flag to indicate if the alarm has been triggered
    always @ (posedge clk)
    begin
        
        if (enableAlarmSW)
            begin
            AlarmLED <= 1;                                                     //alarm LED to indicate that the Alarm is set
            if (Clock_minutes == Alarm_minutes && Clock_seconds == Alarm_seconds)
                 alarmTriggered <= 1;   
                
            if (alarmTriggered)
                  AlarmOutputLED <= 1;
            end
        else
            begin
            alarmTriggered <= 0;
            AlarmLED <= 0;
	    AlarmOutputLED <= 0;
            end
            
    end//end always   
    


endmodule
//============================================================================================






//================================= up and down Counter =========================================
module upandDownCounter (clock, up,down ,switchBetween, resetn   ,seconds, minutes  );   
    input clock;
    input up;
    input down;
    input switchBetween;     
    input resetn;   
    output reg [5:0] seconds, minutes;
    
    
    //always @ (posedge up, posedge down, negedge resetn )     wrong
    //always @ (negedge  up, negedge  down, negedge  resetn )  wrong
    //always @ *                                               wrong, it counts super fast
    //always @ (negedge up or negedge down )                   wrong
    
    
    always @ (posedge clock  )
    begin
        if (resetn)
            begin 
            minutes <= 0;
            seconds <= 0;
            end
        else
            begin          
            if (switchBetween)                //if the switch is up, change the minutes
                begin
                if (up) 
                    if (minutes < 59)
                        minutes <= minutes + 1;                                     
                if (down)
                     if (minutes > 0)
                        minutes <= minutes - 1;                  
                end         
            else                               //if the switch is down, change the seconds
                begin
                if (up) 
                    if (seconds < 59)                  
                        seconds <= seconds + 1;
                if (down)
                    if (seconds > 0)
                        seconds <= seconds - 1;   
                end   
            end//end else                     
    end//end always 

endmodule


//================================= seconds & minutes Counters =======================================
module min_sec_counters(slow_clock, seconds, minutes);
input slow_clock;
output reg [5:0] seconds, minutes;

always@ (posedge slow_clock)
begin
    if (seconds != 6'b111011)                  //if the seconds != 59
        begin 
        seconds <= seconds + 1;
        end
    else                                      //if the seconds = 59
        if (minutes != 6'b111011)             //if the minutes != 59 
            begin
            minutes <= minutes + 1;
            seconds = 0;
            end
        else                                  //if the minutes = 59 ==> the end, start from the zero again
            begin
            minutes <= 0;
            seconds <= 0;
            end     
end
endmodule                                     // remember that         59 = 111 011


//================================ digits separator ==================================================
module digitsSeparator (seconds, minutes,        upperdigitS, lowerdigitS, upperdigitM, lowerdigitM);
input [5:0] seconds;
input [5:0] minutes;
output reg [3:0] upperdigitS;
output reg [3:0] lowerdigitS;
output reg [3:0] upperdigitM;
output reg [3:0] lowerdigitM;

always @*
begin
    upperdigitS = seconds/10;
    lowerdigitS = seconds%10;  
    upperdigitM = minutes/10;
    lowerdigitM = minutes%10;       
end

endmodule 


//=================================== Counter (selectors) ===========================================
module counter3bit (Resetn, Clock, E, Q);
input Resetn, Clock, E;
output reg [2:0] Q;                     

always @(negedge Resetn, posedge Clock)
if (!Resetn)
Q <= 0;
else if (E)
Q <= Q + 1;

endmodule


//==================================== 8 to 1 multiplexer module ======================================
module mux8to1 (select, upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0,upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1,        AN, CX);
input [2:0] select;                     //the two selectors
input [3:0] upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0 ,upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1;   //the inputs

output reg [7:0]AN;                    //the different 8 7-segment-displays
output reg [7:0]CX;                    //the 7-segments

always @ (select, upperdigitS0, lowerdigitS0, upperdigitM0, lowerdigitM0 ,upperdigitS1, lowerdigitS1, upperdigitM1, lowerdigitM1 )
begin
    case(select)                       //case statement to run through 4 digits and display them all together really fast
    3'b000:  
        begin                                                                     
            AN = 8'b01111111;    
            case (upperdigitM1)         //display the minutes upper digit                       
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001;
                9: CX = 8'b00001001; 
            endcase
        end                                           
    3'b001:
        begin                                
            AN = 8'b10111111;    
            case (lowerdigitM1)         //display the minutes lower digit       
                0: CX = 8'b00000010;        
                1: CX = 8'b10011110;        
                2: CX = 8'b00100100;
                3: CX = 8'b00001100;
                4: CX = 8'b10011000;
                5: CX = 8'b01001000;
                6: CX = 8'b01000000;
                7: CX = 8'b00011110;
                8: CX = 8'b00000000;
                9: CX = 8'b00001000; 
            endcase
        end        
    3'b010:
        begin                                
            AN = 8'b11011111;    
            case (upperdigitS1)         //display the seconds upper digit       
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001;
                9: CX = 8'b00001001;   
            endcase
        end             
    3'b011:
        begin                                
            AN = 8'b11101111;    
            case (lowerdigitS1)        //display the seconds lower digit       
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001; 
                9: CX = 8'b00001001;  
             endcase
        end
     3'b100:
        begin                                
            AN = 8'b11110111;    
            case (upperdigitM0)        //     
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001; 
                9: CX = 8'b00001001;  
             endcase
        end 
     3'b101:
        begin                                
            AN = 8'b11111011;    
            case (lowerdigitM0)        //       
                0: CX = 8'b00000010;        
                1: CX = 8'b10011110;        
                2: CX = 8'b00100100;
                3: CX = 8'b00001100;
                4: CX = 8'b10011000;
                5: CX = 8'b01001000;
                6: CX = 8'b01000000;
                7: CX = 8'b00011110;
                8: CX = 8'b00000000; 
                9: CX = 8'b00001000;  
             endcase
        end 
      3'b110:
        begin                                
            AN = 8'b11111101;    
            case (upperdigitS0)        //       
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001; 
                9: CX = 8'b00001001;  
             endcase
        end 
      3'b111:
        begin                                
            AN = 8'b11111110;    
            case (lowerdigitS0)        //       
                0: CX = 8'b00000011;        
                1: CX = 8'b10011111;        
                2: CX = 8'b00100101;
                3: CX = 8'b00001101;
                4: CX = 8'b10011001;
                5: CX = 8'b01001001;
                6: CX = 8'b01000001;
                7: CX = 8'b00011111;
                8: CX = 8'b00000001; 
                9: CX = 8'b00001001;  
             endcase
        end                                                                                                           
    endcase//end the big case of the selectors
end
endmodule 



