module RNN(clk,reset,busy,ready,i_en,idata,mdata_w,mce,mdata_r,maddr,msel);
input           clk, reset;
input           ready;
input    [31:0] idata;
input    [19:0] mdata_r;

output          busy;
output          i_en;
output          mce;
output   [16:0] maddr;
output   [19:0] mdata_w;
output    [2:0] msel;

// Please DO NOT modified the I/O signal
// TODO

integer k;

// State declaration
parameter IDLE = 3'b000;
parameter LENGTH = 3'b001;
parameter READ0 = 3'b010;
parameter READ1 = 3'b011;
parameter READ2 = 3'b100;
parameter READ3 = 3'b101;
parameter WRITE = 3'b110;
parameter FINISH = 3'b111;

// Register declaration
reg [2:0]  state, next_state;
reg signed [19:0] mdata;
reg        busy, next_busy;
reg        i_en, next_i_en;
reg        mce, next_mce;
reg [16:0] maddr, next_maddr;
reg [16:0] waddr, next_waddr;
reg signed [19:0] mdata_w, next_mdata_w;
reg [2:0]  msel, next_msel;

reg [11:0] count, next_count;
reg [5:0]  next_haddr;
reg signed [39:0] next_h;
reg signed [39:0] h[0:63];
reg signed [19:0] next_last_h;
reg signed [19:0] last_h[0:63];

// __________ Combinatioal Part __________

always@(*) begin
case(state)
    IDLE: begin
      if (busy==1'b1) begin
        next_state = LENGTH;
        next_busy = 1'b1;
        next_mce = 1'b1;
        next_i_en = 1'b1;
        next_msel = 3'b000;
      end
      
      else if(ready==1'b1) begin
        next_state = IDLE; // needs to delay one cycle
        next_busy = 1'b1;
        next_mce = 1'b1;
        next_i_en = 1'b0;
        next_msel = 3'b100;
      end
      
      else begin
        next_state = IDLE;
        next_busy = 1'b0;
        next_mce = 1'b0;
        next_i_en = 1'b0;
        next_msel = 3'b000;
      end
      
      next_haddr = 6'd0;
      next_h = h[0];
      next_last_h = last_h[0];
      
      next_count = 12'd0;
      next_maddr = 17'd0;
      next_waddr = waddr;
      next_mdata_w = 20'd0;
    end
    
    LENGTH: begin
      if (waddr>>6==mdata) begin
        next_state = FINISH;
        next_maddr = 17'd0;
      end
      
      else begin
        next_state = READ0;
        next_maddr = maddr + 17'd1;
      end
      
      next_haddr = 6'd0;
      next_h = h[0];
      next_last_h = last_h[0];
      
      next_msel = 3'b000;
      next_count = 12'd0;
      next_waddr = waddr;
      next_mdata_w = 20'd0;
      next_busy = 1'b1;
      next_i_en = 1'b0;
      next_mce = 1'b1;
    end
    
    READ0: begin
      if (maddr==17'd2047) begin
        next_state = READ0;
        next_count = count + 12'd1;
        next_msel = 3'b001;
        next_maddr = 17'd0;
      end
      
      else if (maddr==17'd0) begin
        next_state = READ1;
        next_count = 12'd0;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      else begin
        next_state = READ0;
        next_count = count + 12'd1;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      next_haddr = count>>5;
      next_h = (idata[count[4:0]]==1'b0)? 40'd0 + h[count>>5]:{4'd0, mdata, 16'd0} + h[count>>5];
      next_last_h = last_h[count>>5];
      
      next_waddr = waddr;
      next_mdata_w = 20'd0;
      next_busy = 1'b1;
      next_i_en = 1'b0;
      next_mce = 1'b1;
    end
    
    READ1: begin
      if (maddr==17'd63) begin
        next_state = READ1;
        next_count = count + 12'd1;
        next_msel = 3'b010;
        next_maddr = 17'd0;
      end
      
      else if (maddr==17'd0) begin
        next_state = READ2;
        next_count = 12'd0;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      else begin
        next_state = READ1;
        next_count = count + 12'd1;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      next_haddr = count;
      next_h = {4'd0, mdata, 16'd0} + h[count];
      next_last_h = last_h[count];
      
      next_waddr = waddr;
      next_mdata_w = 20'd0;
      next_busy = 1'b1;
      next_i_en = 1'b0;
      next_mce = 1'b1;
    end
    
    READ2: begin
      if (maddr==17'd4095) begin
        next_state = READ2;
        next_count = count + 12'd1;
        next_msel = 3'b011;
        next_maddr = 17'd0;
      end
      
      else if (maddr==17'd0) begin
        next_state = READ3;
        next_count = 12'd0;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      else begin
        next_state = READ2;
        next_count = count + 12'd1;
        next_msel = msel;
        next_maddr = maddr + 17'd1;
      end
      
      next_haddr = count>>6;
      next_h = mdata*last_h[count[5:0]] + h[count>>6];
      next_last_h = last_h[count>>6];
      
      next_waddr = waddr;
      next_mdata_w = 20'd0;
      next_busy = 1'b1;
      next_i_en = 1'b0;
      next_mce = 1'b1;
    end
    
    READ3: begin
      if (maddr[5:0]==17'd0) begin
        next_state = WRITE;
        next_count = 12'd0;
        next_maddr = waddr;
        next_msel = 3'b101;
        next_mce = 1'b0;
      end
      
      else if (maddr==17'd63) begin
        next_state = READ3;
        next_count = count + 12'd1;
        next_maddr = waddr;
        next_msel = msel;
        next_mce = 1'b0;
      end
      
      else begin
        next_state = READ3;
        next_count = count + 12'd1;
        next_maddr = maddr + 17'd1;
        next_msel = msel;
        next_mce = 1'b1;
      end
      
      next_haddr = count;
      next_h = {4'd0, mdata, 16'd0} + h[count];
      next_last_h = last_h[count];
      
      next_waddr = waddr;
      next_mdata_w = 20'd0;
      next_busy = 1'b1;
      next_i_en = 1'b0;
    end
    
    WRITE: begin
      if (maddr[5:0]==6'b111111) begin
        next_state = IDLE;
        next_count = count + 12'd1;
        next_waddr = waddr;
        next_msel = 3'b100;
      end
      
      else if (count==12'd63) begin
        next_state = WRITE;
        next_count = 12'd0;
        next_waddr = waddr + 17'd1;
        next_msel = msel;
      end
      
      else begin
        next_state = WRITE;
        next_count = count + 12'd1;
        next_waddr = waddr + 17'd1;
        next_msel = msel;
      end
      
      next_haddr = count;
      next_h = h[count];
      if (h[count][35]==1'b0 && h[count][35:16] > 20'h10000) begin
        next_last_h = 20'h10000;
        next_mdata_w = 20'h10000;
      end
      else if (h[count][35]==1'b1 && h[count][35:16] < 20'hf0000) begin
        next_last_h = 20'hf0000;
        next_mdata_w = 20'hf0000;
      end
      else begin
        next_last_h = (h[count][15]==1'b1)? h[count][35:16] + 1'b1:h[count][35:16];
        next_mdata_w = (h[count][15]==1'b1)? h[count][35:16] + 1'b1:h[count][35:16];
      end
      
      next_maddr = waddr;
      next_busy = 1'b1;
      next_i_en = 1'b0;
      next_mce = 1'b1;
    end
    
    FINISH: begin
      next_state = FINISH;
      next_count = 12'd0;
      next_msel = 3'b000;
      next_maddr = 17'd0;
      
      next_haddr = 6'd0;
      next_h = h[0];
      next_last_h = h[0];
      
      next_waddr = 17'd0;
      next_mdata_w = 20'd0;
      next_busy = 1'b0;
      next_i_en = 1'b0;
      next_mce = 1'b0;
    end
  endcase
end

// __________ Sequential Part __________

always@(posedge clk or posedge reset) begin
  if(reset) begin
    state <= IDLE;
    count <= 12'd0;
    busy <= 1'b0;
    i_en <= 1'b0;
    
    for (k=0; k<=63; k=k+1)
      h[k] <= 40'd0;
    
    for (k=0; k<=63; k=k+1)
      last_h[k] <= 20'd0;
    
    maddr <= 17'd0;
    waddr <= 17'd0;
    mdata <= 20'd0;
    mdata_w <= 20'd0;
    msel <= 3'b000;
    mce <= 1'b0;
  end
  
  else begin
    state <= next_state;
    count <= next_count;
    busy <= next_busy;
    i_en <= next_i_en;
    
    for (k=0; k<=63; k=k+1)
      h[k] <= (next_state==LENGTH)? 40'd0:h[k];
    h[next_haddr] <= (next_state==LENGTH)? 40'd0:next_h;
    
    for (k=0; k<=63; k=k+1)
      last_h[k] <= last_h[k];
    last_h[next_haddr] <= next_last_h;
    
    maddr <= next_maddr;
    waddr <= next_waddr;
    mdata <= mdata_r;
    mdata_w <= next_mdata_w;
    msel <= next_msel;
    mce <= next_mce;
  end
end

endmodule

