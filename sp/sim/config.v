`define SYNTHESIS

module ELVDS_OBUF(
            input   wire    I,
            output  wire    O,
            output  wire    OB
        );

    assign O  = I;
    assign OB = ~I;

endmodule

module OSER10
    (
        output  wire    Q    ,
        input   wire    D0   ,
        input   wire    D1   ,
        input   wire    D2   ,
        input   wire    D3   ,
        input   wire    D4   ,
        input   wire    D5   ,
        input   wire    D6   ,
        input   wire    D7   ,
        input   wire    D8   ,
        input   wire    D9   ,
        input   wire    PCLK ,
        input   wire    FCLK ,
        input   wire    RESET
    );

endmodule

module OSERDESE2 #(
   parameter         DATA_RATE_OQ       = "DDR",
   parameter         DATA_RATE_TQ       = "DDR",
   parameter integer DATA_WIDTH         = 4,
   parameter [0:0]   INIT_OQ            = 1'b0,
   parameter [0:0]   INIT_TQ            = 1'b0,
   parameter [0:0]   IS_CLKDIV_INVERTED = 1'b0,
   parameter [0:0]   IS_CLK_INVERTED    = 1'b0,
   parameter [0:0]   IS_D1_INVERTED     = 1'b0,
   parameter [0:0]   IS_D2_INVERTED     = 1'b0,
   parameter [0:0]   IS_D3_INVERTED     = 1'b0,
   parameter [0:0]   IS_D4_INVERTED     = 1'b0,
   parameter [0:0]   IS_D5_INVERTED     = 1'b0,
   parameter [0:0]   IS_D6_INVERTED     = 1'b0,
   parameter [0:0]   IS_D7_INVERTED     = 1'b0,
   parameter [0:0]   IS_D8_INVERTED     = 1'b0,
   parameter [0:0]   IS_T1_INVERTED     = 1'b0,
   parameter [0:0]   IS_T2_INVERTED     = 1'b0,
   parameter [0:0]   IS_T3_INVERTED     = 1'b0,
   parameter [0:0]   IS_T4_INVERTED     = 1'b0,
   parameter         SERDES_MODE        = "MASTER",
   parameter [0:0]   SRVAL_OQ           = 1'b0,
   parameter [0:0]   SRVAL_TQ           = 1'b0,
   parameter         TBYTE_CTL          = "FALSE",
   parameter         TBYTE_SRC          = "FALSE",
   parameter integer TRISTATE_WIDTH     = 4
)(
   output OFB,
   output OQ,
   output SHIFTOUT1,
   output SHIFTOUT2,
   output TBYTEOUT,
   output TFB,
   output TQ,

   input  CLK,
   input  CLKDIV,
   input  D1,
   input  D2,
   input  D3,
   input  D4,
   input  D5,
   input  D6,
   input  D7,
   input  D8,
   input  OCE,
   input  RST,
   input  SHIFTIN1,
   input  SHIFTIN2,
   input  T1,
   input  T2,
   input  T3,
   input  T4,
   input  TBYTEIN,
   input  TCE
);
endmodule: OSERDESE2