--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	signal w_btnU : std_logic;
	signal f_A : std_logic_vector(7 downto 0) := x"00";
	signal f_B : std_logic_vector(7 downto 0) := x"00";
	
	signal w_result : std_logic_vector(7 downto 0);
	signal w_flags : std_logic_vector(3 downto 0);
	signal w_bin : std_logic_vector(7 downto 0);
	signal w_cycle : std_logic_vector(3 downto 0);
	
	signal w_hund : std_logic_vector(3 downto 0);
	signal w_tens : std_logic_vector(3 downto 0);
	signal w_ones : std_logic_vector(3 downto 0);
	signal w_sign_bit : std_logic;
	signal w_sign_hex : std_logic_vector(3 downto 0);
	
	signal w_clk : std_logic;
	signal w_sel : std_logic_vector(3 downto 0);
	signal w_hex : std_logic_vector(3 downto 0);
	signal w_seg : std_logic_vector(6 downto 0);
	signal w_sign_seg : std_logic_vector(6 downto 0);
	signal f_btnC_1 : std_logic := '0';
	signal f_btnC_2 : std_logic := '0';
	signal w_btnC_pulse : std_logic;

    component controller_fsm is
        port(i_clk : in STD_LOGIC;
       i_reset : in STD_LOGIC;
       i_adv : in STD_LOGIC;
       o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
       );
       end component;

    component ALU is 
        port(
            i_A : in STD_LOGIC_VECTOR (7 downto 0);
            i_B  : in STD_LOGIC_VECTOR (7 downto 0);
            i_op : in STD_LOGIC_VECTOR (2 downto 0);
            o_result : out STD_LOGIC_VECTOR (7 downto 0);
            o_flags  : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component ALU;
    
    component twos_comp is
        port (
            i_bin : in std_logic_vector(7 downto 0);
            o_sign : out std_logic;
            o_hund : out std_logic_vector(3 downto 0);
            o_tens : out std_logic_vector(3 downto 0);
            o_ones : out std_logic_vector(3 downto 0)
        );
    end component twos_comp;    
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2 );
        port ( 
            i_clk : in std_logic;
            i_reset : in std_logic;
            o_clk : out std_logic
        );
    end component clock_divider;
    
      component TDM4 is
        generic ( constant k_WIDTH : natural := 4 );
        Port ( 
            i_clk : in  STD_LOGIC;
            i_reset : in  STD_LOGIC;
            i_D3 : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D2 : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D1 : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D0 : in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_data : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_sel : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component TDM4;
    

    component sevenseg_decoder is 
        Port ( 
            i_Hex   : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
      
begin
	-- PORT MAPS ----------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                f_btnC_1 <= '0';
                f_btnC_2 <= '0';
            else
                f_btnC_1 <= btnC;
                f_btnC_2 <= f_btnC_1;
        end if;
        end if;
    end process;
    
    w_btnC_pulse <= f_btnC_1 and not f_btnC_2;
	    w_btnU <= btnU;


        controller_inst: controller_fsm
        port map(
           i_clk => clk,
           i_reset => w_btnU,
           i_adv => w_btnC_pulse,
           o_cycle => w_cycle	
        );


    ALU_inst: ALU
        port map(
            i_A  => f_A,
            i_B  => f_B,
            i_op   => sw(2 downto 0),
            o_result => w_result,
            o_flags  => w_flags
        );


    twos_comp_inst: twos_comp
        port map(
            i_bin  => w_bin,
            o_sign => w_sign_bit,
            o_hund => w_hund,
            o_tens => w_tens,
            o_ones => w_ones
        );


    clock_inst: clock_divider 
        generic map ( 
            k_DIV => 100000 
        ) 
        port map(
            i_clk => clk,
            i_reset => w_btnU,
            o_clk => w_clk
        );


    TDM4_inst: TDM4
        generic map (
            k_WIDTH => 4
        )
        port map(
            i_clk => w_clk,
            i_reset => w_btnU,
            i_D3 => w_sign_hex,
            i_D2 => w_hund,
            i_D1 => w_tens,
            i_D0 => w_ones, 
            o_data => w_hex,
            o_sel => w_sel
        );
    sevenseg_inst: sevenseg_decoder
        port map(
            i_Hex => w_hex,
            o_seg_n => w_seg
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if w_btnU = '1' then
                f_A <= x"00";
                f_B <= x"00";

            elsif w_btnC_pulse = '1' then
                -- when leaving clear state grab first number
                if w_cycle = "0001" then f_A <= sw;

                -- when leaving first op state grab second number
                elsif w_cycle = "0010" then f_B <= sw;
                    end if;
                    end if;
                    end if;
                    end process;
    -- mux for selecting A, B, result, blank
    with w_cycle select
        w_bin <= f_A when "0010",
                 f_B when "0100",
                 w_result when "1000",
                 x"00" when others;


    -- blanks display in first state
    with w_cycle select
        an <= "1111" when "0001",
              w_sel when others;

    w_sign_hex <= "0000";


    with w_sign_bit select
        w_sign_seg <= "0111111" when '1',
                      "1111111" when others;
    with w_sel select
        seg <= w_sign_seg when "0111", w_seg when others;
    led(3 downto 0) <= w_cycle;
    led(11 downto 4) <= (others => '0');
    led(15 downto 12) <= w_flags;
    
end top_basys3_arch;