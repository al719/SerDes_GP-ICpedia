package decoder_env_pkg;
 
 import uvm_pkg::*;
`include "uvm_macros.svh"
import my_config_db_pkg::*;


`define create(type , inst_name) type::type_id::create(inst_name,this);


/////////// SEQ_ITEM ///////////////////

class decoder_seq_itm extends uvm_sequence_item;
    `uvm_object_utils(decoder_seq_itm);

  logic                                 decoder_CLK                  ;
  logic                                 decoder_Rst_n                ;
  logic [9:0]                           decoder_Data_in              ;
  logic [7:0]                           decoder_Data_out             ;
  logic                                 decoder_DecodeError          ;
  logic                                 decoder_DisparityError       ;
  logic                                 decoder_RxDataK              ;


    function new(string name = "decoder_seq_itm");
      super.new(name);
    endfunction

endclass

/////////////////// MONITOR /////////////////////

class decoder_mon extends uvm_monitor;
 `uvm_component_utils(decoder_mon);

 uvm_analysis_port #(decoder_seq_itm) mon_port;
 decoder_seq_itm  data_to_send;
 virtual PASSIVE_if passive_vif;


   function new(string name = "decoder_mon" , uvm_component parent = null);
     super.new(name,parent);
   endfunction  


   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      mon_port = new("mon_port" , this);
     `uvm_info("decoder_mon","BUILD_PHASE",UVM_LOW);
   endfunction


  task run_phase(uvm_phase phase);
     super.run_phase(phase);

     forever begin
       data_to_send = `create(decoder_seq_itm, "data_to_send");
       @(negedge  passive_vif.decoder_CLK);
       data_to_send.decoder_Data_out = passive_vif.decoder_Data_out;

       mon_port.write(data_to_send);
     end
   endtask  

 
endclass


///////////////// SB ////////////////////////

class decoder_sb extends uvm_scoreboard;

 `uvm_component_utils(decoder_sb);

 uvm_analysis_export #(decoder_seq_itm)  sb_export;
 decoder_seq_itm  data_to_chk;
 uvm_tlm_analysis_fifo #(decoder_seq_itm)  sb_fifo;


  virtual PASSIVE_if passive_vif;


   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      sb_export.connect(sb_fifo.analysis_export);
    endfunction


   function new(string name = "decoder_sb" , uvm_component parent = null);
     super.new(name,parent);
   endfunction  


   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
      
      sb_export    = new("sb_export" , this);
      sb_fifo       = new("sb_fifo", this);      
      data_to_chk  = new("data_to_chk");

    if (!uvm_config_db#(virtual PASSIVE_if)::get(this, "" , "passive_if" , passive_vif)) begin
          `uvm_fatal("DECODER", "FATAL GETTING intf");
    end

     `uvm_info("decoder_sb","BUILD_PHASE",UVM_LOW);
   endfunction


   task run_phase(uvm_phase phase);
     super.run_phase(phase);
     forever begin
      @(posedge passive_vif.decoder_CLK);
      sb_fifo.get(data_to_chk);
      `uvm_info("DECODER_SCOREBOARD", $sformatf("OUT_DATA = %h", data_to_chk.decoder_Data_out), UVM_LOW);             
     end
   endtask 

endclass



//////////////////// AGENT ///////////////////////

class decoder_agt extends uvm_agent;

 `uvm_component_utils(decoder_agt);

 decoder_config_db  decoder_cfg;
 decoder_mon mon;

  uvm_analysis_port #(decoder_seq_itm) agt_port;

   function new(string name = "decoder_agt" , uvm_component parent = null);
     super.new(name,parent);
   endfunction  


   function void build_phase(uvm_phase phase);
     super.build_phase(phase);

     agt_port = new("agt_port" , this);
     mon = `create(decoder_mon , "mon");

     decoder_cfg = `create(decoder_config_db, "decoder_cfg");

    if(!uvm_config_db#(decoder_config_db)::get(this,"","DECODER_CFG",decoder_cfg)) begin
          `uvm_fatal("decoder_agt", "FATAL GETTING CFG");        
    end     

     `uvm_info("decoder_agt","BUILD_PHASE",UVM_LOW);
   endfunction

   
   function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
     mon.mon_port.connect(agt_port);
     mon.passive_vif = decoder_cfg.passive_vif;
   endfunction
 
endclass


////////////////// ENV /////////////////////////

 class decoder_env extends uvm_env;
    `uvm_component_utils(decoder_env);
   
  decoder_agt agt;
  decoder_sb  sb;


   function new(string name = "decoder_env" , uvm_component parent = null);
     super.new(name,parent);
   endfunction  


   function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     
     agt = `create(decoder_agt,"agt");
     sb  = `create(decoder_sb,"sb");

     `uvm_info("decoder_env","BUILD_PHASE",UVM_LOW);
   endfunction


   function void connect_phase(uvm_phase phase);
     super.connect_phase(phase);
      agt.agt_port.connect(sb.sb_export);
   endfunction
 
 endclass
endpackage