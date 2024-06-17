`timescale 1ns / 1ps

module tb_RV32I ();

    logic        clk;
    logic        reset;
    tri   [15:0] IOPortA;
    // tri [15:0] IOPortB;
    tri   [15:0] IOPortB;
    // tri [15:0] IOPortD;
    // tri [15:0] IOPortE;
    // tri [15:0] IOPortH;
    logic        UART_RX1;
    logic        UART_TX1;
    logic [15:0] ioC;

    assign IOPortA = ioC;

    RV32I dut (
        .clk(clk),
        .reset(reset),
        .IOPortA(IOPortA),
        .IOPortB(IOPortB),
        //.IOPortC(IOPortC),
        // .IOPortD(),
        // .IOPortE(),
        // .IOPortH()
        .fndFont(),
        .fndCom(),
        .UART_RX1(UART_RX1),
        .UART_TX1(UART_TX1)
    );

    always #1 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1'b1;
        UART_RX1 = 1;
        #40 reset = 1'b0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 1;

        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 1;


        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 0;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 1;
        #20800 UART_RX1 = 1;

        for (int i = 0; i < 1000; i++) begin
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 1;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 1;
            #20800 UART_RX1 = 1;

            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 1;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 1;
            #20800 UART_RX1 = 0;
            #20800 UART_RX1 = 1;


        end
        #2000 UART_RX1 = 0;
        #640000 UART_RX1 = 0;
        #640000 UART_RX1 = 0;
        #640000 UART_RX1 = 1;
        #640000 UART_RX1 = 0;
        #640000 UART_RX1 = 1;
        #640000 UART_RX1 = 1;
        #640000 UART_RX1 = 1;
        #640000 UART_RX1 = 1;



    end




endmodule
