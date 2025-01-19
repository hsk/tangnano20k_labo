-------------------------------------------------------------------------------
--
-- Synthesizable model of TI's SN76489AN.
--
-- $Id: sn76489_top.vhd,v 1.9 2006/02/27 20:30:10 arnim Exp $
--
-- Chip Toplevel
--
-- References:
--
--   * TI Data sheet SN76489.pdf
--     ftp://ftp.whtech.com/datasheets%20&%20manuals/SN76489.pdf
--
--   * John Kortink's article on the SN76489:
--     http://web.inter.nl.net/users/J.Kortink/home/articles/sn76489/
--
--   * Maxim's "SN76489 notes" in
--     http://www.smspower.org/maxim/docs/SN76489.txt
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2005, 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee, work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity sn76489_top is

  generic (
    clock_div_16_g : integer := 1
  );
  port (
    clock_i    : in  std_logic;
    clock_en_i : in  std_logic;
    res_n_i    : in  std_logic;
    ce_n_i     : in  std_logic;
    we_n_i     : in  std_logic;
    ready_o    : out std_logic;
    d_i        : in  std_logic_vector(0 to 7);
    aout_o     : out std_logic_vector(0 to 7)
  );

end sn76489_top;


library ieee;
use ieee.numeric_std.all;

architecture struct of sn76489_top is

  signal clk_en_s    : boolean;

  signal tone1_we_s,
         tone2_we_s,
         tone3_we_s,
         noise_we_s  : boolean;
  signal r2_s        : std_logic;

  signal tone1_s,
         tone2_s,
         tone3_s,
         noise_s     : std_logic_vector(0 to 7);

  signal tone3_ff_s  : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Clock Divider
  -----------------------------------------------------------------------------
  clock_div_b : sn76489_clock_div
    generic map (
      clock_div_16_g => clock_div_16_g
    )
    port map (
      clock_i    => clock_i,
      clock_en_i => clock_en_i,
      res_n_i    => res_n_i,
      clk_en_o   => clk_en_s
    );


  -----------------------------------------------------------------------------
  -- Latch Control = CPU Interface
  -----------------------------------------------------------------------------
  latch_ctrl_b : sn76489_latch_ctrl
    port map (
      clock_i    => clock_i,
      clk_en_i   => clk_en_s,
      res_n_i    => res_n_i,
      ce_n_i     => ce_n_i,
      we_n_i     => we_n_i,
      d_i        => d_i,
      ready_o    => ready_o,
      tone1_we_o => tone1_we_s,
      tone2_we_o => tone2_we_s,
      tone3_we_o => tone3_we_s,
      noise_we_o => noise_we_s,
      r2_o       => r2_s
    );


  -----------------------------------------------------------------------------
  -- Tone Channel 1
  -----------------------------------------------------------------------------
  tone1_b : sn76489_tone
    port map (
      clock_i  => clock_i,
      clk_en_i => clk_en_s,
      res_n_i  => res_n_i,
      we_i     => tone1_we_s,
      d_i      => d_i,
      r2_i     => r2_s,
      ff_o     => open,
      tone_o   => tone1_s
    );

  -----------------------------------------------------------------------------
  -- Tone Channel 2
  -----------------------------------------------------------------------------
  tone2_b : sn76489_tone
    port map (
      clock_i  => clock_i,
      clk_en_i => clk_en_s,
      res_n_i  => res_n_i,
      we_i     => tone2_we_s,
      d_i      => d_i,
      r2_i     => r2_s,
      ff_o     => open,
      tone_o   => tone2_s
    );

  -----------------------------------------------------------------------------
  -- Tone Channel 3
  -----------------------------------------------------------------------------
  tone3_b : sn76489_tone
    port map (
      clock_i  => clock_i,
      clk_en_i => clk_en_s,
      res_n_i  => res_n_i,
      we_i     => tone3_we_s,
      d_i      => d_i,
      r2_i     => r2_s,
      ff_o     => tone3_ff_s,
      tone_o   => tone3_s
    );

  -----------------------------------------------------------------------------
  -- Noise Channel
  -----------------------------------------------------------------------------
  noise_b : sn76489_noise
    port map (
      clock_i    => clock_i,
      clk_en_i   => clk_en_s,
      res_n_i    => res_n_i,
      we_i       => noise_we_s,
      d_i        => d_i,
      r2_i       => r2_s,
      tone3_ff_i => tone3_ff_s,
      noise_o    => noise_s
    );


  aout_o <= tone1_s + tone2_s + tone3_s + noise_s;

end struct;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity sn76489_clock_div is

  generic (
    clock_div_16_g : integer := 1
  );
  port (
    clock_i    : in  std_logic;
    clock_en_i : in  std_logic;
    res_n_i    : in  std_logic;
    clk_en_o   : out boolean
  );

end sn76489_clock_div;


library ieee;
use ieee.numeric_std.all;

architecture rtl of sn76489_clock_div is

  signal cnt_s,
         cnt_q  : std_logic_vector(3 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --   Implements the sequential counter element.
  --
  seq: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      cnt_q <= (others => '0');
    elsif clock_i'event and clock_i = '1' then
      cnt_q <= cnt_s;
    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process comb
  --
  -- Purpose:
  --   Implements the combinational counter logic.
  --
  comb: process (clock_en_i,
                 cnt_q)
  begin
    -- default assignments
    cnt_s    <= cnt_q;
    clk_en_o <= false;

    if clock_en_i = '1' then

      if cnt_q = 0 then
        clk_en_o <= true;

        if clock_div_16_g = 1 then
          cnt_s  <= conv_std_logic_vector(15, cnt_q'length);
        elsif clock_div_16_g = 0 then
          cnt_s  <= conv_std_logic_vector( 1, cnt_q'length);
        else
          -- pragma translate_off
          assert false
            report "Generic clock_div_16_g must be either 0 or 1."
            severity failure;
          -- pragma translate_on
        end if;

      else
        cnt_s    <= cnt_q - 1;

      end if;

    end if;

  end process comb;
  --
  -----------------------------------------------------------------------------

end rtl;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity sn76489_latch_ctrl is

  port (
    clock_i    : in  std_logic;
    clk_en_i   : in  boolean;
    res_n_i    : in  std_logic;
    ce_n_i     : in  std_logic;
    we_n_i     : in  std_logic;
    d_i        : in  std_logic_vector(0 to 7);
    ready_o    : out std_logic;
    tone1_we_o : out boolean;
    tone2_we_o : out boolean;
    tone3_we_o : out boolean;
    noise_we_o : out boolean;
    r2_o       : out std_logic
  );

end sn76489_latch_ctrl;


library ieee;
use ieee.numeric_std.all;

architecture rtl of sn76489_latch_ctrl is

  signal reg_q   : std_logic_vector(0 to 2);
  signal we_q    : boolean;
  signal ready_q : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Process seq
  --
  -- Purpose:
  --   Implements the sequential elements.
  --
  seq: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      reg_q     <= (others => '0');
      we_q      <= false;
      ready_q   <= '0';

    elsif clock_i'event and clock_i = '1' then
      -- READY Flag Output ----------------------------------------------------
      if ready_q = '0' and we_q then
        if clk_en_i then
          -- assert READY when write access happened
          ready_q <= '1';
        end if;
      elsif ce_n_i = '1' then
        -- deassert READY when access has finished
        ready_q <= '0';
      end if;

      -- Register Selection ---------------------------------------------------
      if ce_n_i = '0' and we_n_i = '0' then
        if clk_en_i then
          if d_i(0) = '1' then
            reg_q <= d_i(1 to 3);
          end if;
          we_q  <= true;
        end if;
      else
        we_q  <= false;
      end if;

    end if;
  end process seq;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  tone1_we_o <= reg_q(0 to 1) = "00" and we_q;
  tone2_we_o <= reg_q(0 to 1) = "01" and we_q;
  tone3_we_o <= reg_q(0 to 1) = "10" and we_q;
  noise_we_o <= reg_q(0 to 1) = "11" and we_q;

  r2_o       <= reg_q(2);

  ready_o    <=   ready_q
                when ce_n_i = '0' else
                  '1';

end rtl;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


library ieee, work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity sn76489_tone is

  port (
    clock_i  : in  std_logic;
    clk_en_i : in  boolean;
    res_n_i  : in  std_logic;
    we_i     : in  boolean;
    d_i      : in  std_logic_vector(0 to 7);
    r2_i     : in  std_logic;
    ff_o     : out std_logic;
    tone_o   : out std_logic_vector(0 to 7)
  );

end sn76489_tone;

architecture rtl of sn76489_tone is

  signal f_q        : std_logic_vector(0 to 9);
  signal a_q        : std_logic_vector(0 to 3);
  signal freq_cnt_q : std_logic_vector(0 to 9);
  signal freq_ff_q  : std_logic;

  function all_zero(a : in std_logic_vector) return boolean is
    variable result_v : boolean;
  begin
    result_v := true;

    for idx in a'low to a'high loop
      if a(idx) /= '0' then
        result_v := false;
      end if;
    end loop;

    return result_v;
  end;

begin

  -----------------------------------------------------------------------------
  -- Process cpu_regs
  --
  -- Purpose:
  --   Implements the registers writable by the CPU.
  --
  cpu_regs: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      f_q <= (others => '0');
      a_q <= (others => '1');

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i and we_i then
        if r2_i = '0' then
          -- access to frequency register
          if d_i(0) = '0' then
            f_q(0 to 5) <= d_i(2 to 7);
          else
            f_q(6 to 9) <= d_i(4 to 7);
          end if;

        else
          -- access to attenuator register
          -- both access types can write to the attenuator register!
          a_q <= d_i(4 to 7);

        end if;
      end if;
    end if;
  end process cpu_regs;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process freq_gen
  --
  -- Purpose:
  --   Implements the frequency generation components.
  --
  freq_gen: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      freq_cnt_q <= (others => '0');
      freq_ff_q  <= '0';

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i then
        if freq_cnt_q = 0 then
          -- update counter from frequency register
          freq_cnt_q <= f_q;

          -- and toggle the frequency flip-flop if enabled
          if not all_zero(f_q) then
            freq_ff_q <= not freq_ff_q;
          else
            -- if frequency setting is 0, then keep flip-flop at +1
            freq_ff_q <= '1';
          end if;

        else
          -- decrement frequency counter
          freq_cnt_q <= freq_cnt_q - 1;

        end if;
      end if;
    end if;
  end process freq_gen;


  -----------------------------------------------------------------------------
  -- The attenuator itself
  -----------------------------------------------------------------------------
  attenuator_b : sn76489_attenuator
    port map (
      attenuation_i => a_q,
      factor_i      => freq_ff_q,
      product_o     => tone_o
    );


  -----------------------------------------------------------------------------
  -- Output mapping
  -----------------------------------------------------------------------------
  ff_o <= freq_ff_q;

end rtl;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


library ieee, work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity sn76489_noise is

  port (
    clock_i    : in  std_logic;
    clk_en_i   : in  boolean;
    res_n_i    : in  std_logic;
    we_i       : in  boolean;
    d_i        : in  std_logic_vector(0 to 7);
    r2_i       : in  std_logic;
    tone3_ff_i : in  std_logic;
    noise_o    : out std_logic_vector(0 to 7)
  );

end sn76489_noise;


architecture rtl of sn76489_noise is

  signal nf_q       : std_logic_vector(0 to 1);
  signal fb_q       : std_logic;
  signal a_q        : std_logic_vector(0 to 3);
  signal freq_cnt_q : std_logic_vector(0 to 6);
  signal freq_ff_q  : std_logic;

  signal shift_source_s,
         shift_source_q    : std_logic;
  signal shift_rise_edge_s : boolean;

  signal lfsr_q            : std_logic_vector(0 to 15);

begin

  -----------------------------------------------------------------------------
  -- Process cpu_regs
  --
  -- Purpose:
  --   Implements the registers writable by the CPU.
  --
  cpu_regs: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      nf_q <= (others => '0');
      fb_q <= '0';
      a_q  <= (others => '1');

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i and we_i then
        if r2_i = '0' then
          -- access to control register
          -- both access types can write to the control register!
          nf_q <= d_i(6 to 7);
          fb_q <= d_i(5);

        else
          -- access to attenuator register
          -- both access types can write to the attenuator register!
          a_q <= d_i(4 to 7);

        end if;
      end if;
    end if;
  end process cpu_regs;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Process freq_gen
  --
  -- Purpose:
  --   Implements the frequency generation components.
  --
  freq_gen: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      freq_cnt_q <= (others => '0');
      freq_ff_q  <= '0';

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i then
        if freq_cnt_q = 0 then
          -- reload frequency counter according to NF setting
          case nf_q is
            when "00" =>
              freq_cnt_q <= conv_std_logic_vector(16 * 2 - 1, freq_cnt_q'length);
            when "01" =>
              freq_cnt_q <= conv_std_logic_vector(16 * 4 - 1, freq_cnt_q'length);
            when "10" =>
              freq_cnt_q <= conv_std_logic_vector(16 * 8 - 1, freq_cnt_q'length);
            when others =>
              null;
          end case;

          freq_ff_q <= not freq_ff_q;

        else
          -- decrement frequency counter
          freq_cnt_q <= freq_cnt_q - 1;

        end if;

      end if;
    end if;
  end process freq_gen;
  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- Multiplex the source of the LFSR's shift enable
  -----------------------------------------------------------------------------
  shift_source_s <=   tone3_ff_i
                    when nf_q = "11" else
                      freq_ff_q;

  -----------------------------------------------------------------------------
  -- Process rise_edge
  --
  -- Purpose:
  --   Detect the rising edge of the selected LFSR shift source.
  --
  rise_edge: process (clock_i, res_n_i)
  begin
    if res_n_i = '0' then
      shift_source_q <= '0';

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i then
        shift_source_q <= shift_source_s;
      end if;
    end if;
  end process rise_edge;
  --
  -----------------------------------------------------------------------------

  -- detect rising edge on shift source
  shift_rise_edge_s <= shift_source_q = '0' and shift_source_s = '1';


  -----------------------------------------------------------------------------
  -- Process lfsr
  --
  -- Purpose:
  --   Implements the LFSR that generates noise.
  --   Note: This implementation shifts the register right, i.e. from index
  --         15 towards 0 => bit 15 is the input, bit 0 is the output
  --
  --   Tapped bits according to MAME's sn76496.c, implemented in function
  --   lfsr_tapped_f.
  --
  lfsr: process (clock_i, res_n_i)

    function lfsr_tapped_f(lfsr : in std_logic_vector) return std_logic is
      constant tapped_bits_c : std_logic_vector(0 to 15)
        -- tapped bits are 0, 2, 15
        := "1010000000000001";
      variable parity_v : std_logic;
    begin
      parity_v := '0';

      for idx in lfsr'low to lfsr'high loop
        parity_v := parity_v xor (lfsr(idx) and tapped_bits_c(idx));
      end loop;

      return parity_v;
    end;

  begin
    if res_n_i = '0' then
      -- reset LFSR to "0000000000000001"
      lfsr_q               <= (others => '0');
      lfsr_q(lfsr_q'right) <= '1';

    elsif clock_i'event and clock_i = '1' then
      if clk_en_i then
        if we_i and r2_i = '0' then
          -- write to noise register
          -- -> reset LFSR
          lfsr_q               <= (others => '0');
          lfsr_q(lfsr_q'right) <= '1';

        elsif shift_rise_edge_s then

          -- shift LFSR left towards MSB
          for idx in lfsr_q'right-1 downto lfsr_q'left loop
            lfsr_q(idx) <= lfsr_q(idx+1);
          end loop;

          -- determine input bit
          if fb_q = '0' then
            -- "Periodic" Noise
            -- -> input to LFSR is output
            lfsr_q(lfsr_q'right) <= lfsr_q(lfsr_q'left);
          else
            -- "White" Noise
            -- -> input to LFSR is parity of tapped bits
            lfsr_q(lfsr_q'right) <= lfsr_tapped_f(lfsr_q);
          end if;

        end if;

      end if;
    end if;
  end process lfsr;

  -----------------------------------------------------------------------------
  -- The attenuator itself
  -----------------------------------------------------------------------------
  attenuator_b : sn76489_attenuator
    port map (
      attenuation_i => a_q,
      factor_i      => lfsr_q(0),
      product_o     => noise_o
    );

end rtl;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity sn76489_attenuator is

  port (
    attenuation_i : in  std_logic_vector(0 to 3);
    factor_i      : in  std_logic;
    product_o     : out std_logic_vector(0 to 7)
  );

end sn76489_attenuator;


architecture rtl of sn76489_attenuator is
    type     volume_t is array (natural range 0 to 15) of natural;
    constant volume_c : volume_t := (31, 25, 20, 16, 12, 10, 8, 6, 5, 4, 3, 2, 2, 2, 1, 0);
begin

  -----------------------------------------------------------------------------
  -- Process attenuate
  --
  -- Purpose:
  --   Determine the attenuation and generate the resulting product.
  --
  --   The maximum attenuation value is 31 which corresponds to volume off.
  --   As described in the data sheet, the maximum "playing" attenuation is
  --     28 = 16 + 8 + 4
  --
  --   The table for the volume constants is derived from the following
  --   formula (each step is 2dB voltage):
  --     v(0)   = 31
  --     v(n+1) = v(n) * 0.79432823
  --

  product_o <= conv_std_logic_vector(volume_c(conv_integer(attenuation_i)), product_o'length) when factor_i = '1'
          else (others => '0');

end rtl;
