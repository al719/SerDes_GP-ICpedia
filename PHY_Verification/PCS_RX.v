module PCS_RX #(
    parameter DATA_WIDTH = 10,
    BUFFER_WIDTH = 10,
    BUFFER_DEPTH = 16
) (

    //input 					K285			, // to comma block
    input [DATA_WIDTH-1:0] Collected_Data,
    input WordClk,  // to elastic buffer & decoder & Gasket
    input PCLK,
    input recovered_clk_5G,
    input Rst_n,
    input [5:0] DataBusWidth,

    output [31:0] RX_Data,
    output        RX_DataK,
    output [ 2:0] RX_Status,
    output        RX_Valid
);

  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 	  internal wires	   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  wire Comma_pulse, overflow, skp_added, Skp_Removed, underflow;
  wire [DATA_WIDTH-1:0] data_to_decoder;
  wire [7:0] data_to_gasket;
  wire DecodeError, Disparity_Error;
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 	Comma Detection 	   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////

  Comma_Detection Comma_Detection_U (
      .clk           (recovered_clk_5G),
      .rst_n         (Rst_n),
      .COMMA_NUMBER  (DataBusWidth / 8),
      .Data_Collected(Collected_Data),
      .RxValid       (RX_Valid),
      .Comma_Pulse   (Comma_pulse)
  );


  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 	Elastic Buffer  	   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  elasticBuffer #(
      .DATA_WIDTH  (BUFFER_WIDTH),
      .BUFFER_DEPTH(BUFFER_DEPTH)
  ) buffer (
      .write_clk  (Comma_pulse),      // pulse from comma detection
      .read_clk   (WordClk),          // in port
      .data_in    (Collected_Data),   // from serial to parallel
      .rst_n      (Rst_n),            // inport
      .data_out   (data_to_decoder),  // to decoder
      .overflow   (overflow),         // to rx status
      .skp_added  (skp_added),        // to rx status
      .Skp_Removed(Skp_Removed),      // to rx status
      .underflow  (underflow)         // to rx status
  );

  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 		 Decoder		   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  decoder decode (
      .Rst_n         (Rst_n),            // in port
      .Data_in       (data_to_decoder),  // from elastic buffer
      .CLK           (WordClk),          // clk 250 or 125 MHz 
      .RxDataK       (RX_DataK),         // out port
      .Data_out      (data_to_gasket),   // to gasket
      .DecodeError   (DecodeError),      // to rx status
      .DisparityError(Disparity_Error)   // to rx status
  );
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 		 RX_Status		   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  Reeceiver_Status rx_status (
      .Skp_Removed    (Skp_Removed),      // from elastic buffer
      .Overflow       (overflow),         // from elastic buffer
      .Underflow      (underflow),        // from elastic buffer
      .Skp_Added      (skp_added),        // from elastic buffer
      .Decode_Error   (DecodeError),      // from decoder
      .Disparity_Error(Disparity_Error),  // from decoder
      .RxStatus       (RX_Status)         // out port
  );
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  //////////////// 			Gasket	   	   /////////////////
  ////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////
  GasKet_RX rx_gasket (
      .clk_to_get(WordClk),         // in port
      .PCLK      (PCLK),            // in port
      .Rst_n     (Rst_n),           // in port
      .Data_in   (data_to_gasket),  // from decoder
      .width     (DataBusWidth),    // in port
      .Rx_Datak  (RX_DataK),
      .Data_out  (RX_Data)          // final out port
  );
endmodule
