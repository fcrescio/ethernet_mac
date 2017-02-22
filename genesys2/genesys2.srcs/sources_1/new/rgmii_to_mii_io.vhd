----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/21/2017 12:36:16 PM
-- Design Name: 
-- Module Name: rgmii_to_mii_io - kintex_7
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.ethernet_types.all;


entity rgmii_to_mii_io is
    Port ( clock_125_i : in STD_ULOGIC;
           speed_select_i : in t_ethernet_speed;

           rgmii_rxd_i : in STD_ULOGIC_vector(3 downto 0);
           rgmii_rxctl_i : in STD_ULOGIC;
           rgmii_rxc_i : in STD_ULOGIC;
           rgmii_txd_o : out STD_ULOGIC_vector(3 downto 0);
           rgmii_txctl_o : out STD_ULOGIC;
           rgmii_txc_o : out STD_ULOGIC;

           int_mii_tx_er_i : in STD_ULOGIC;
           int_mii_tx_en_i : in STD_ULOGIC;
           int_mii_txd_i   : in std_ulogic_vector(7 downto 0);
           int_mii_rx_er_o : out  std_ulogic;
           int_mii_rx_dv_o : out  std_ulogic;
           int_mii_rxd_o   : out  std_ulogic_vector(7 downto 0);

           rx_clock_o : out std_ulogic;
           tx_clock_o : out std_ulogic
           );
end rgmii_to_mii_io;

architecture kintex_7 of rgmii_to_mii_io is
   signal rxc_a, rxc_b : std_ulogic;
   signal txc_a, txc_b : std_ulogic;
begin

   RXC_inst : IDDR 
   generic map (
      DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE" 
                                       -- or "SAME_EDGE_PIPELINED" 
      INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
      INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
      SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC" 
   port map (
      Q1 => rxc_a, -- 1-bit output for positive edge of clock 
      Q2 => rxc_b, -- 1-bit output for negative edge of clock
      C => rgmii_rxc_i,   -- 1-bit clock input
      CE => '1', -- 1-bit clock enable input
      D => rgmii_rxctl_i,   -- 1-bit DDR data input
      R => '0',   -- 1-bit reset
      S => open    -- 1-bit set
      );
      
    int_mii_rx_dv_o <= rxc_a;
    int_mii_rx_er_o <= rxc_a xor rxc_b;

    gen_rxd : for I in 0 to 3 generate
       RXD_inst : IDDR 
        generic map (
            DDR_CLK_EDGE => "SAME_EDGE_PIPELINED", -- "OPPOSITE_EDGE", "SAME_EDGE" 
                                       -- or "SAME_EDGE_PIPELINED" 
            INIT_Q1 => '0', -- Initial value of Q1: '0' or '1'
            INIT_Q2 => '0', -- Initial value of Q2: '0' or '1'
            SRTYPE => "SYNC") -- Set/Reset type: "SYNC" or "ASYNC" 
        port map (
            Q1 => int_mii_rxd_o(I), -- 1-bit output for positive edge of clock 
            Q2 => int_mii_rxd_o(I+4), -- 1-bit output for negative edge of clock
            C => rgmii_rxc_i,   -- 1-bit clock input
            CE => '1', -- 1-bit clock enable input
            D => rgmii_rxd_i(I),   -- 1-bit DDR data input
            R => '0',   -- 1-bit reset
            S => open    -- 1-bit set
        );
    end generate gen_rxd;

    rx_clock_o <= rgmii_rxc_i;

    -- to support 10/100 operations this clocks should be divided by 50 and 5
    tx_clock_o <= clock_125_i;
    rgmii_txc_o <= clock_125_i;
    
    txc_a <= int_mii_tx_en_i;
    txc_b <= int_mii_tx_en_i xor int_mii_tx_er_i;
    
    txc_inst : ODDR
    generic map(
       DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
       INIT => '0',   -- Initial value for Q port ('1' or '0')
       SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map (
       Q => rgmii_txctl_o,   -- 1-bit DDR output
       C => clock_125_i,    -- 1-bit clock input
       CE => '1',  -- 1-bit clock enable input
       D1 => txc_a,  -- 1-bit data input (positive edge)
       D2 => txc_b,  -- 1-bit data input (negative edge)
       R => '0',    -- 1-bit reset input
       S => open     -- 1-bit set input
    );
    
    gen_txd : for I in 0 to 3 generate
        txc_inst : ODDR
            generic map(
                DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
                INIT => '0',   -- Initial value for Q port ('1' or '0')
                SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
            port map (
                Q => rgmii_txd_o(I),   -- 1-bit DDR output
                C => clock_125_i,    -- 1-bit clock input
                CE => '1',  -- 1-bit clock enable input
                D1 => int_mii_txd_i(I),  -- 1-bit data input (positive edge)
                D2 => int_mii_txd_i(I+4),  -- 1-bit data input (negative edge)
                R => '0',    -- 1-bit reset input
                S => open     -- 1-bit set input
            );
    end generate gen_txd;

end kintex_7;
