//
// Primitive declarations
//

property persistency(clk,irdy,trdy,rst);
  @(posedge clk) disable iff(rst) (irdy && ~trdy |=> irdy);
endproperty

property liveness(clk,irdy,trdy,rst);
  @(posedge clk) disable iff(rst) (irdy |-> ##[0:$] (irdy && trdy));
endproperty

property arbiter_fairness (clk, rst, irdy, trdy);
  @(posedge clk) disable iff(rst) 
  (irdy |-> ##[0:$] (irdy && trdy));
endproperty

property arbiter_fairness_1 (clk, rst, irdy, trdy);
  @(posedge clk) disable iff(rst)
  (irdy |-> ##[0:1] (irdy && trdy));
endproperty

property arbiter_fairness_0 (clk, rst, irdy, trdy);
  @(posedge clk) disable iff(rst)
  (irdy |-> (irdy && trdy));
endproperty

module SRC$reqrsp (clk, rst, t
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input [63:0] t;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Source 
  wire generator;
  wire newgen;
  reg pre;
  // Generator function:
  // 
  assign generator = rst? 0 : (1);
  always @(posedge clk) pre <= rst? 0 : o0$irdy && !o0$trdy;
  assign o0$irdy = generator || pre;
  assign newgen = generator && !pre;
  // Equations:
  // type == 0 || type == 1
  reg [1:0] prevo0$data$type;
  assign o0$data$type = newgen? 1: prevo0$data$type;
  always @(posedge clk) prevo0$data$type <= o0$data$type;
  // Assertion: The source is persistent
  assert_SRC$reqrsp_persistent: 
  assert property (persistency(.clk(clk), .irdy(o0$irdy), .trdy(o0$trdy), .rst(rst)));
  assert_SRC$reqrsp_alive:
         assert property (@(posedge clk) disable iff(rst)
                          (o0$irdy |-> ##[0:$] o0$trdy));
  assert_SRC$reqrsp_only_req:
         assert property (@(posedge clk) disable iff(rst)
                          (o0$data$type == 0));
endmodule
module SRC$req (clk, rst, t
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input [63:0] t;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Source 
  wire generator;
  wire newgen;
  reg pre;
  // Generator function:
  // 
  assign generator = rst? 0 : (1);
  always @(posedge clk) pre <= rst? 0 : o0$irdy && !o0$trdy;
  assign o0$irdy = generator || pre;
  assign newgen = generator && !pre;
  // Equations:
  // type == 0
  reg [1:0] prevo0$data$type;
  assign o0$data$type = newgen?0 : prevo0$data$type;
  always @(posedge clk) prevo0$data$type <= o0$data$type;

  assert_SRC$req_persistent:
  assert property (persistency(.clk(clk), .rst(rst), .irdy(o0$irdy), .trdy(o0$trdy)));
  assert_SRC$req_alive:
  assert property (liveness(.clk(clk), .rst(rst), .irdy(o0$irdy), .trdy(o0$trdy)));
endmodule
module Q$q1 (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Queue of size 2
  reg [0:0] in;
  reg [0:0] out;
  wire [0:0] nextin = (in==(2-1)) ? 0 : (in+1);
  wire [0:0] nextout = (out==(2-1)) ? 0 : (out+1);
  // Queue memory
  reg [1:0] data$type$addr0;
  reg [1:0] data$type$addr1;
  reg full;
  assign i0$trdy = !full;
  assign o0$irdy = !(in==out) || full;
  assign o0$data$type = (out==(0)?data$type$addr0:data$type$addr1);
  wire writing = i0$irdy && i0$trdy; // writing into the queue
  wire reading = o0$irdy && o0$trdy; // reading from the queue
  always @(posedge clk) in <= rst ? 0 : (writing ? nextin : in);
  always @(posedge clk) out <= rst ? 0 : (reading ? nextout : out);
  always @(posedge clk) full <= (rst || reading) ? 0 : ((nextin==out && writing) ? 1 : full);
  always @(posedge clk) data$type$addr0 <= (writing && (in==(0)))?i0$data$type : data$type$addr0;
  always @(posedge clk) data$type$addr1 <= (writing && (in==(1)))?i0$data$type : data$type$addr1;

  assert_q1_never_full: assert property (@(posedge clk) (i0$trdy)); // queue always accepting
  assert_q1_delay_0_1: assert property (@(posedge clk) (i0$irdy |-> ##[0:1] o0$irdy));
  assert_q1_delay_1: assert property (@(posedge clk) (i0$irdy & ~o0$irdy |-> ##[1:1] o0$irdy & o0$trdy));
endmodule
module SNK$snk (clk, rst, t
    ,i0$trdy,i0$irdy,i0$data$type
  );
  input clk, rst;
  input [63:0] t;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  // Sink 
  reg generator;
  reg pre;
  // Generator function:
  // 
  always @(posedge clk) generator <= (1);
  always @(posedge clk) pre <= i0$trdy && !i0$irdy && !rst;
  assign i0$trdy = generator || pre;
endmodule
module SW$switch (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,o0$trdy,o0$irdy,o0$data$type
    ,o1$trdy,o1$irdy,o1$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  output o1$irdy;
  input o1$trdy;
  output [1:0] o1$data$type;
  // Switch
  wire [0:0] sel;
  // Equation:
  // type == 1
  assign sel = (i0$data$type==1);
  // Data path
  assign i0$trdy = (o0$trdy && o0$irdy) || (o1$trdy && o1$irdy);
  assign o0$irdy = i0$irdy && sel;
  assign o1$irdy = i0$irdy && !sel;
  assign o0$data$type = i0$data$type;
  assign o1$data$type = i0$data$type;
endmodule
module MRG$merge2 (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,i1$trdy,i1$irdy,i1$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  input i1$irdy;
  output i1$trdy;
  input [1:0] i1$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Merge 
  wire arb0$sel;
  wire [1:0] arb0$data$type;
  wire arb0$irdy;
  wire arb0$trdy;
  merge2arb inarb0(.clk(clk), .rst(rst)
  , .i0$irdy(i0$irdy)
  , .i0$trdy(i0$trdy)
  , .i1$irdy(i1$irdy)
  , .i1$trdy(i1$trdy)
  , .o0$irdy(arb0$irdy)
  , .o0$trdy(arb0$trdy)
  , .sel(arb0$sel)
  );
  assign arb0$data$type = arb0$sel ? i1$data$type : i0$data$type;
  assign o0$irdy = arb0$irdy;
  assign arb0$trdy = o0$trdy;
  assign o0$data$type = arb0$data$type;
  // Fairness of arbitration
  assert_merge2_fair0:
  assert property (arbiter_fairness(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge2_fair0_1:
  assert property (arbiter_fairness_1(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge2_fair0_0:
  assert property (arbiter_fairness_0(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge2_fair1:
  assert property (arbiter_fairness(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));
  assert_merge2_fair1_1:
  assert property (arbiter_fairness_1(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));
  assert_merge2_fair1_0:
  assert property (arbiter_fairness_0(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));

endmodule
module CJN$join (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,i1$trdy,i1$irdy,i1$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  input i1$irdy;
  output i1$trdy;
  input [1:0] i1$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // CtrlJoin
  assign o0$irdy = i0$irdy && i1$irdy;
  // Equation:
  // 0
  assign i0$trdy = o0$trdy && i1$irdy;
  assign i1$trdy = o0$trdy && i0$irdy;
  assign o0$data$type = i0$data$type; 
  assert_CJN_correct_1:
  assert property (@(posedge clk) disable iff(rst) 
         (i0$irdy && i0$trdy |-> i1$irdy && i1$trdy));
  assert_CJN_correct_2:
  assert property (@(posedge clk) disable iff(rst) 
         (i1$irdy && i1$trdy |-> i0$irdy && i0$trdy));
  assert_CJN_correct_3:
  assert property (@(posedge clk) disable iff(rst)
         (i1$irdy && i1$trdy |-> o0$irdy && o0$trdy));
  assert_CJN_correct_4:
  assert property (@(posedge clk) disable iff(rst)
         (o0$irdy && o0$trdy |-> i1$irdy && i1$trdy));
  assert_CJN_correct_5:
  assert property (@(posedge clk) disable iff(rst)
         (i1$irdy && i1$trdy |-> o0$irdy && o0$trdy));
  assert_CJN_correct_6:
  assert property (@(posedge clk) disable iff(rst)
         (o0$irdy && o0$trdy |-> i1$irdy && i1$trdy));  

endmodule
module FUN$torsp (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Function 
  assign i0$trdy = o0$trdy;
  assign o0$irdy = i0$irdy;
  // Equations:
  // type := 1
  assign o0$data$type = 1;
  // Deleted fields:
endmodule
module Q$q0 (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Queue of size 2
  reg [0:0] in;
  reg [0:0] out;
  wire [0:0] nextin = (in==(2-1)) ? 0 : (in+1);
  wire [0:0] nextout = (out==(2-1)) ? 0 : (out+1);
  // Queue memory
  reg [1:0] data$type$addr0;
  reg [1:0] data$type$addr1;
  reg full;
  assign i0$trdy = !full;
  assign o0$irdy = !(in==out) || full;
  assign o0$data$type = (out==(0)?data$type$addr0:data$type$addr1);
  wire writing = i0$irdy && i0$trdy; // writing into the queue
  wire reading = o0$irdy && o0$trdy; // reading from the queue
  always @(posedge clk) in <= rst ? 0 : (writing ? nextin : in);
  always @(posedge clk) out <= rst ? 0 : (reading ? nextout : out);
  always @(posedge clk) full <= (rst || reading) ? 0 : ((nextin==out && writing) ? 1 : full);
  always @(posedge clk) data$type$addr0 <= (writing && (in==(0)))?i0$data$type : data$type$addr0;
  always @(posedge clk) data$type$addr1 <= (writing && (in==(1)))?i0$data$type : data$type$addr1;
endmodule
module FRK$fork (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,o0$trdy,o0$irdy,o0$data$type
    ,o1$trdy,o1$irdy,o1$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  output o1$irdy;
  input o1$trdy;
  output [1:0] o1$data$type;
  // Fork 
  assign i0$trdy = o0$trdy && o1$trdy;
  assign o0$irdy = i0$irdy && o1$trdy;
  assign o1$irdy = i0$irdy && o0$trdy;
  assign o0$data$type = i0$data$type;
  assign o1$data$type = i0$data$type;

  assert_FRK_correct_1:
  assert property (@(posedge clk) disable iff(rst)
         (o0$irdy && o0$trdy |-> o1$irdy && o1$trdy));
  assert_FRK_correct_2:
  assert property (@(posedge clk) disable iff(rst)
         (o1$irdy && o1$trdy |-> o0$irdy && o0$trdy));
  assert_FRK_correct_3:
  assert property (@(posedge clk) disable iff(rst)
         (o1$irdy && o1$trdy |-> i0$irdy && i0$trdy));
  assert_FRK_correct_4:
  assert property (@(posedge clk) disable iff(rst)
         (i0$irdy && i0$trdy |-> o1$irdy && o1$trdy));
  assert_FRK_correct_5:
  assert property (@(posedge clk) disable iff(rst)
         (i0$irdy && i0$trdy |-> o0$irdy && o0$trdy));
  assert_FRK_correct_6:
  assert property (@(posedge clk) disable iff(rst)
         (o0$irdy && o0$trdy |-> i0$irdy && i0$trdy));

endmodule
module MRG$merge1 (clk, rst
    ,i0$trdy,i0$irdy,i0$data$type
    ,i1$trdy,i1$irdy,i1$data$type
    ,o0$trdy,o0$irdy,o0$data$type
  );
  input clk, rst;
  input i0$irdy;
  output i0$trdy;
  input [1:0] i0$data$type;
  input i1$irdy;
  output i1$trdy;
  input [1:0] i1$data$type;
  output o0$irdy;
  input o0$trdy;
  output [1:0] o0$data$type;
  // Merge 
  wire arb0$sel;
  wire [1:0] arb0$data$type;
  wire arb0$irdy;
  wire arb0$trdy;
  merge2arb inarb0(.clk(clk), .rst(rst)
  , .i0$irdy(i0$irdy)
  , .i0$trdy(i0$trdy)
  , .i1$irdy(i1$irdy)
  , .i1$trdy(i1$trdy)
  , .o0$irdy(arb0$irdy)
  , .o0$trdy(arb0$trdy)
  , .sel(arb0$sel)
  );
  assign arb0$data$type = arb0$sel ? i1$data$type : i0$data$type;
  assign o0$irdy = arb0$irdy;
  assign arb0$trdy = o0$trdy;
  assign o0$data$type = arb0$data$type;

  // Fairness of arbitration
  assert_merge1_fair0:
  assert property (arbiter_fairness(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge1_fair0_1:
  assert property (arbiter_fairness_1(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge1_fair0_0:
  assert property (arbiter_fairness_0(.clk(clk), .rst(rst), .irdy(i0$irdy), .trdy(i0$trdy)));
  assert_merge1_fair1:
  assert property (arbiter_fairness(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));
  assert_merge1_fair1_1:
  assert property (arbiter_fairness_1(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));
  assert_merge1_fair1_0:
  assert property (arbiter_fairness_0(.clk(clk), .rst(rst), .irdy(i1$irdy), .trdy(i1$trdy)));

endmodule
//
// Top level module
//
// Merge 2-input arbitrator
module merge2arb(clk, rst, i0$irdy, i0$trdy, i1$irdy, i1$trdy, o0$irdy, o0$trdy, sel);
input clk;
input rst;
input i0$irdy;
output i0$trdy;
input i1$irdy;
output i1$trdy;
output o0$irdy;
input o0$trdy;
output sel;
// Arbitration state
reg prevSel;
reg transfer;
// Arbitration logic
always @(posedge clk) prevSel <= rst ? 0 : sel;
always @(posedge clk) transfer <= rst ? 0 : o0$irdy && o0$trdy;
assign sel = rst ? 0 : (i0$irdy && !i1$irdy) ? 0 : (i1$irdy && !i0$irdy) ? 1 : transfer ? !prevSel : prevSel;
assign o0$irdy = i0$irdy || i1$irdy;
assign i0$trdy = !sel && o0$trdy && i0$irdy;
assign i1$trdy = sel && o0$trdy && i1$irdy;
endmodule
module top
(clk, rst, t
);
input clk;
input rst;
input [63:0] t;
//
// Signal declarations
//
// Driven by inst0, 'reqrsp'
wire sig0$o0$irdy;
wire [1:0] sig0$o0$data$type;
// Driven by inst1, 'req'
wire sig1$o0$irdy;
wire [1:0] sig1$o0$data$type;
// Driven by inst2, 'q1'
wire sig2$i0$trdy;
wire sig2$o0$irdy;
wire [1:0] sig2$o0$data$type;
// Driven by inst3, 'snk'
wire sig3$i0$trdy;
// Driven by inst4, 'switch'
wire sig4$i0$trdy;
wire sig4$o0$irdy;
wire sig4$o1$irdy;
wire [1:0] sig4$o0$data$type;
wire [1:0] sig4$o1$data$type;
// Driven by inst5, 'merge2'
wire sig5$i0$trdy;
wire sig5$i1$trdy;
wire sig5$o0$irdy;
wire [1:0] sig5$o0$data$type;
// Driven by inst6, 'join'
wire sig6$i0$trdy;
wire sig6$i1$trdy;
wire sig6$o0$irdy;
wire [1:0] sig6$o0$data$type;
// Driven by inst7, 'torsp'
wire sig7$i0$trdy;
wire sig7$o0$irdy;
wire [1:0] sig7$o0$data$type;
// Driven by inst8, 'q0'
wire sig8$i0$trdy;
wire sig8$o0$irdy;
wire [1:0] sig8$o0$data$type;
// Driven by inst9, 'fork'
wire sig9$i0$trdy;
wire sig9$o0$irdy;
wire sig9$o1$irdy;
wire [1:0] sig9$o0$data$type;
wire [1:0] sig9$o1$data$type;
// Driven by inst10, 'merge1'
wire sig10$i0$trdy;
wire sig10$i1$trdy;
wire sig10$o0$irdy;
wire [1:0] sig10$o0$data$type;
//
// Primitive instantiations
//
// Primitive inst0, 'reqrsp', SRC
SRC$reqrsp i0$SRC$reqrsp(.clk(clk), .rst(rst), .t(t)
  , .o0$irdy(sig0$o0$irdy)
  , .o0$trdy(sig9$i0$trdy)
  , .o0$data$type(sig0$o0$data$type)
);
// Primitive inst1, 'req', SRC
SRC$req i1$SRC$req(.clk(clk), .rst(rst), .t(t)
  , .o0$irdy(sig1$o0$irdy)
  , .o0$trdy(sig10$i1$trdy)
  , .o0$data$type(sig1$o0$data$type)
);
// Primitive inst2, 'q1', Q
Q$q1 i2$Q$q1(.clk(clk), .rst(rst)
  , .i0$irdy(sig10$o0$irdy)
  , .i0$trdy(sig2$i0$trdy)
  , .i0$data$type(sig10$o0$data$type)
  , .o0$irdy(sig2$o0$irdy)
  , .o0$trdy(sig4$i0$trdy)
  , .o0$data$type(sig2$o0$data$type)
);
// Primitive inst3, 'snk', SNK
SNK$snk i3$SNK$snk(.clk(clk), .rst(rst), .t(t)
  , .i0$irdy(sig5$o0$irdy)
  , .i0$trdy(sig3$i0$trdy)
  , .i0$data$type(sig5$o0$data$type)
);
// Primitive inst4, 'switch', SW
SW$switch i4$SW$switch(.clk(clk), .rst(rst)
  , .i0$irdy(sig2$o0$irdy)
  , .i0$trdy(sig4$i0$trdy)
  , .i0$data$type(sig2$o0$data$type)
  , .o0$irdy(sig4$o0$irdy)
  , .o1$irdy(sig4$o1$irdy)
  , .o0$trdy(sig7$i0$trdy)
  , .o1$trdy(sig5$i1$trdy)
  , .o0$data$type(sig4$o0$data$type)
  , .o1$data$type(sig4$o1$data$type)
);
// Primitive inst5, 'merge2', MRG
MRG$merge2 i5$MRG$merge2(.clk(clk), .rst(rst)
  , .i0$irdy(sig6$o0$irdy)
  , .i1$irdy(sig4$o1$irdy)
  , .i0$trdy(sig5$i0$trdy)
  , .i1$trdy(sig5$i1$trdy)
  , .i0$data$type(sig6$o0$data$type)
  , .i1$data$type(sig4$o1$data$type)
  , .o0$irdy(sig5$o0$irdy)
  , .o0$trdy(sig3$i0$trdy)
  , .o0$data$type(sig5$o0$data$type)
);
// Primitive inst6, 'join', CJN
CJN$join i6$CJN$join(.clk(clk), .rst(rst)
  , .i0$irdy(sig8$o0$irdy)
  , .i1$irdy(sig7$o0$irdy)
  , .i0$trdy(sig6$i0$trdy)
  , .i1$trdy(sig6$i1$trdy)
  , .i0$data$type(sig8$o0$data$type)
  , .i1$data$type(sig7$o0$data$type)
  , .o0$irdy(sig6$o0$irdy)
  , .o0$trdy(sig5$i0$trdy)
  , .o0$data$type(sig6$o0$data$type)
);
// Primitive inst7, 'torsp', FUN
FUN$torsp i7$FUN$torsp(.clk(clk), .rst(rst)
  , .i0$irdy(sig4$o0$irdy)
  , .i0$trdy(sig7$i0$trdy)
  , .i0$data$type(sig4$o0$data$type)
  , .o0$irdy(sig7$o0$irdy)
  , .o0$trdy(sig6$i1$trdy)
  , .o0$data$type(sig7$o0$data$type)
);
// Primitive inst8, 'q0', Q
Q$q0 i8$Q$q0(.clk(clk), .rst(rst)
  , .i0$irdy(sig9$o0$irdy)
  , .i0$trdy(sig8$i0$trdy)
  , .i0$data$type(sig9$o0$data$type)
  , .o0$irdy(sig8$o0$irdy)
  , .o0$trdy(sig6$i0$trdy)
  , .o0$data$type(sig8$o0$data$type)
);
// Primitive inst9, 'fork', FRK
FRK$fork i9$FRK$fork(.clk(clk), .rst(rst)
  , .i0$irdy(sig0$o0$irdy)
  , .i0$trdy(sig9$i0$trdy)
  , .i0$data$type(sig0$o0$data$type)
  , .o0$irdy(sig9$o0$irdy)
  , .o1$irdy(sig9$o1$irdy)
  , .o0$trdy(sig8$i0$trdy)
  , .o1$trdy(sig10$i0$trdy)
  , .o0$data$type(sig9$o0$data$type)
  , .o1$data$type(sig9$o1$data$type)
);
// Primitive inst10, 'merge1', MRG
MRG$merge1 i10$MRG$merge1(.clk(clk), .rst(rst)
  , .i0$irdy(sig9$o1$irdy)
  , .i1$irdy(sig1$o0$irdy)
  , .i0$trdy(sig10$i0$trdy)
  , .i1$trdy(sig10$i1$trdy)
  , .i0$data$type(sig9$o1$data$type)
  , .i1$data$type(sig1$o0$data$type)
  , .o0$irdy(sig10$o0$irdy)
  , .o0$trdy(sig2$i0$trdy)
  , .o0$data$type(sig10$o0$data$type)
);

// Global assertions

// Latency from the request source
assert_LATENCY_req: 
      assert property (@(posedge clk) disable iff (rst)
                      // source req sends
                      // other source is silent
                      (i1$SRC$req.o0$irdy 
                   |-> ##[0:1] i1$SRC$req.o0$trdy 
                        ##[0:0] i3$SNK$snk.i0$irdy && i3$SNK$snk.i0$trdy 
                           && ~i3$SNK$snk.i0$data$type));

assert_LATENCY_req_check: 
      assert property (@(posedge clk) disable iff (rst)
         (i1$SRC$req.o0$irdy 
         |=> i3$SNK$snk.i0$irdy && i3$SNK$snk.i0$trdy
                           && ~i3$SNK$snk.i0$data$type));

assert_LATENCY_rsp_check:
      assert property (@(posedge clk) disable iff (rst)
         (i0$SRC$reqrsp.o0$irdy
         |=> ##[0:1] i3$SNK$snk.i0$irdy && i3$SNK$snk.i0$trdy
                           && i3$SNK$snk.i0$data$type));

assert_LATENCY_rsp:
      assert property (@(posedge clk) disable iff (rst)
                      // source req sends
                      // other source is silent
                      (i0$SRC$reqrsp.o0$irdy
                   |-> ##[0:1] i0$SRC$reqrsp.o0$trdy
                        ##[0:1] i3$SNK$snk.i0$irdy && i3$SNK$snk.i0$trdy
                           && i3$SNK$snk.i0$data$type));


int latency = 0;
always @(posedge clk) latency <= (rst) ? 0 : latency + (i2$Q$q1.o0$irdy & i2$Q$q1.o0$data$type == $past(i2$Q$q1.o0$data$type));
assert_latency_cnt: assert property (@(posedge clk) disable iff (rst) (latency < 2));
assert_latency_cnt_fail: assert property (@(posedge clk) disable iff (rst) (latency == 0));

reg[1:0] q1_trdy_toggle_cnt = 2'b00;
always @(posedge clk) q1_trdy_toggle_cnt <= rst ? 0 : q1_trdy_toggle_cnt + ~i2$Q$q1.o0$trdy;
assert_trdy_never_toggles_anymore: assert property (@(posedge clk) disable iff (rst) (q1_trdy_toggle_cnt < 2));

endmodule
