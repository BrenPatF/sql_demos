CREATE OR REPLACE PACKAGE BODY Timer_Set AS
/***************************************************************************************************
GitHub Project:  sql_demos - Brendan's repo for interesting problems and solutions in SQL
                 https://github.com/BrenPatF/sql_demos

Description: This package contains procedures to facilitate PL/SQL code timing. An initial version
             was published on Scribd in 2010, followed by updates to 2012. I copied the Scribd
             article to my blog for easier access recently:

                 'Code Timing and Object Orientation and Zombies'
                 http://aprogrammerwrites.eu/?p=1632

             v1.2 was published with two other utility packages for the articles linked in the link
             below:

                 Utils:    General utilities
                 UT_Utils: Utility procedures for Brendan's database unit testing framework

Further details: 'TRAPIT - TRansactional API Testing in Oracle'
                 http://aprogrammerwrites.eu/?p=1723

Modification History
Who                  When        Which What
-------------------- ----------- ----- -------------------------------------------------------------
Brendan Furey        22-Nov-2010 1.0   Initial version
Brendan Furey        25-Sep-2012 1.1   Final Scribd version
Brendan Furey        08-May-2016 1.2   Factored out 'pretty printing' into general utility Utils
Brendan Furey        21-May-2016 1.3   Type name changed

***************************************************************************************************/
TYPE timer_rec IS RECORD (
        name                        VARCHAR2(30),
        ela_interval                INTERVAL DAY(1) TO SECOND,
        cpu_interval                INTEGER,
        n_calls                     INTEGER);
TYPE timer_arr IS VARRAY(100) OF timer_rec;
TYPE timer_set_rec IS RECORD (
        timer_set_name              VARCHAR2(100),
        start_time                  TIMESTAMP,
        prior_time                  TIMESTAMP,
        start_time_cpu              INTEGER,
        prior_time_cpu              INTEGER,
        timer_list                  timer_arr);

TYPE hash_arr IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(30);
TYPE timer_set_h_rec IS RECORD (timer_set  timer_set_rec, timer_hash hash_arr);
TYPE timer_set_arr IS TABLE OF timer_set_h_rec;

g_timer_set_list timer_set_arr;

/***************************************************************************************************

Construct: Construct a new timer set, returning its id

***************************************************************************************************/
FUNCTION Construct (p_timer_set_name VARCHAR2) -- timer set name
                    RETURN PLS_INTEGER IS      -- timer set id
  l_start_time           TIMESTAMP := SYSTIMESTAMP;
  l_start_time_cpu       PLS_INTEGER := DBMS_Utility.Get_CPU_Time;
  l_new_ind              PLS_INTEGER;
  l_timer_set            timer_set_rec;
  l_timer_set_h          timer_set_h_rec;
BEGIN

  l_timer_set.timer_set_name		:= p_timer_set_name;
  l_timer_set.start_time		:= l_start_time;
  l_timer_set.prior_time		:= l_start_time;
  l_timer_set.start_time_cpu		:= l_start_time_cpu;
  l_timer_set.prior_time_cpu		:= l_start_time_cpu;
  l_timer_set_h.timer_set               := l_timer_set;

  IF g_timer_set_list IS NULL THEN
    l_new_ind := 1;
    g_timer_set_list := timer_set_arr (l_timer_set_h);
  ELSE
    l_new_ind := g_timer_set_list.LAST + 1;
    g_timer_set_list.EXTEND;
    g_timer_set_list (l_new_ind).timer_set := l_timer_set;
  END IF;

  RETURN l_new_ind;

END Construct;

/***************************************************************************************************

Destroy: Destroy a timer set

***************************************************************************************************/
PROCEDURE Destroy (p_timer_set_ind PLS_INTEGER) IS -- timer set id
BEGIN

  g_timer_set_list.DELETE (p_timer_set_ind);

END Destroy;

/***************************************************************************************************

Init_Time: Reset the prior time values, to current, for a timer set

***************************************************************************************************/
PROCEDURE Init_Time (p_timer_set_ind PLS_INTEGER) IS -- timer set id
BEGIN

  g_timer_set_list (p_timer_set_ind).timer_set.prior_time := SYSTIMESTAMP;
  g_timer_set_list (p_timer_set_ind).timer_set.prior_time_cpu := DBMS_Utility.Get_CPU_Time;

END Init_Time;

/***************************************************************************************************

Increment_Time: Increment the timing accumulators for a timer set and timer

***************************************************************************************************/
PROCEDURE Increment_Time (p_timer_set_ind       PLS_INTEGER, -- timer set id
                          p_timer_name          VARCHAR2) IS -- timer name

  l_cpu_time            INTEGER := DBMS_Utility.Get_CPU_Time;
  l_systimestamp        TIMESTAMP := SYSTIMESTAMP;
  l_timer_ind           PLS_INTEGER := 0;
  l_timer               timer_rec;

  l_timer_list          timer_arr := g_timer_set_list (p_timer_set_ind).timer_set.timer_list;
  l_timer_hash          hash_arr := g_timer_set_list (p_timer_set_ind).timer_hash;
  l_prior_time          TIMESTAMP := g_timer_set_list (p_timer_set_ind).timer_set.prior_time;
  l_prior_time_cpu      PLS_INTEGER := g_timer_set_list (p_timer_set_ind).timer_set.prior_time_cpu;

BEGIN

  l_timer.name          := p_timer_name;
  l_timer.ela_interval  := l_systimestamp - l_prior_time;
  l_timer.cpu_interval  := l_cpu_time - l_prior_time_cpu;
  l_timer.n_calls       := 1;
  IF l_timer_list IS NULL THEN

    l_timer_list := timer_arr (l_timer);
    g_timer_set_list (p_timer_set_ind).timer_set.timer_list := l_timer_list;
    g_timer_set_list (p_timer_set_ind).timer_hash (p_timer_name) := 1;

  ELSE

    IF l_timer_hash.EXISTS (p_timer_name) THEN

      l_timer_ind := l_timer_hash (p_timer_name);
      g_timer_set_list (p_timer_set_ind).timer_set.timer_list (l_timer_ind).ela_interval := l_timer_list (l_timer_ind).ela_interval + l_systimestamp - l_prior_time;
      g_timer_set_list (p_timer_set_ind).timer_set.timer_list (l_timer_ind).cpu_interval := l_timer_list (l_timer_ind).cpu_interval + l_cpu_time - l_prior_time_cpu;
      g_timer_set_list (p_timer_set_ind).timer_set.timer_list (l_timer_ind).n_calls := l_timer_list (l_timer_ind).n_calls + 1;

    ELSE

      l_timer_ind := l_timer_list.COUNT + 1;
      g_timer_set_list (p_timer_set_ind).timer_set.timer_list.EXTEND;
      g_timer_set_list (p_timer_set_ind).timer_set.timer_list (l_timer_ind) := l_timer;
      g_timer_set_list (p_timer_set_ind).timer_hash (p_timer_name) := l_timer_ind;

    END IF;

  END IF;

  g_timer_set_list (p_timer_set_ind).timer_set.prior_time := l_systimestamp;
  g_timer_set_list (p_timer_set_ind).timer_set.prior_time_cpu := l_cpu_time;

END Increment_Time;

/***************************************************************************************************

Get_Timer_Stats: Return the details for a given timer set and timer

***************************************************************************************************/
FUNCTION Get_Timer_Stats (p_timer_set_ind       PLS_INTEGER,                    -- timer set id
                          p_timer_name          VARCHAR2 DEFAULT c_timer_total) -- timer name
                          RETURN                timer_stat_rec IS                -- timer details
  l_timer_ind       PLS_INTEGER;
  l_timer           timer_rec;
  l_timer_stat_rec   timer_stat_rec;
BEGIN


  IF g_timer_set_list (p_timer_set_ind).timer_hash.EXISTS (p_timer_name) THEN

    l_timer_ind := g_timer_set_list (p_timer_set_ind).timer_hash (p_timer_name);
    l_timer := g_timer_set_list (p_timer_set_ind).timer_set.timer_list (l_timer_ind);

    l_timer_stat_rec.timer_set_name := g_timer_set_list (p_timer_set_ind).timer_set.timer_set_name;
    l_timer_stat_rec.ela_secs := Utils.Get_Seconds (l_timer.ela_interval);
    l_timer_stat_rec.cpu_secs := 0.01*l_timer.cpu_interval;
    l_timer_stat_rec.calls := l_timer.n_calls;

  END IF;
  RETURN l_timer_stat_rec;

END Get_Timer_Stats;

/***************************************************************************************************

Timer_Avg_Ela_MS: Return the elapsed time in ms for a given timer set and timer

***************************************************************************************************/
FUNCTION Timer_Avg_Ela_MS (p_timer_set_ind      PLS_INTEGER,   -- timer set id
                           p_timer_name         VARCHAR2)      -- timer name
                           RETURN               PLS_INTEGER IS -- elapsed time in ms
  l_timer_stat_rec   timer_stat_rec;
BEGIN

   l_timer_stat_rec := Get_Timer_Stats (p_timer_set_ind, p_timer_name);

  RETURN (l_timer_stat_rec.ela_secs / l_timer_stat_rec.calls) * 1000;

END Timer_Avg_Ela_MS;

/***************************************************************************************************

Write_Header: Write column headers for timer set report

***************************************************************************************************/
PROCEDURE Write_Header (p_type          VARCHAR2,       -- value of first column header
                        p_head_len      PLS_INTEGER) IS -- length of first column
BEGIN

  Utils.Col_Headers (L1_chr_arr (p_type, 'Elapsed', 'CPU', 'Calls', 'Ela/Call', 'CPU/Call'),
                       L1_num_arr (p_head_len, -10, -10, -12, -13, -13));
END Write_Header;

/***************************************************************************************************

Form_Time: Format a numeric time as a string

***************************************************************************************************/
FUNCTION Form_Time (p_time      INTEGER,               -- time to format
                    p_dp        PLS_INTEGER DEFAULT 2) -- decimal places
                    RETURN      VARCHAR2 IS            -- formatted time
  l_dp_zeros  VARCHAR2(10) := Substr ('0000000000', 1, p_dp);
BEGIN
  IF p_dp > 0 THEN l_dp_zeros := '.' || l_dp_zeros; END IF;
  RETURN To_Char (p_time, '99,990' || l_dp_zeros);
END Form_Time;

/***************************************************************************************************

Form_Calls: Format number of calls as a string

***************************************************************************************************/
FUNCTION Form_Calls (p_calls    INTEGER)    -- number of calls
                     RETURN     VARCHAR2 IS -- formatted number of calls
BEGIN
  RETURN To_Char (p_calls, '999,999,990');
END Form_Calls;

/***************************************************************************************************

Write_Time_Line: Write a formatted timing line

***************************************************************************************************/
PROCEDURE Write_Time_Line (p_timer      VARCHAR2,            -- timer name
                           p_head_len   PLS_INTEGER,         -- length of timer column
                           p_ela        NUMBER,              -- elapsed time
                           p_cpu        NUMBER,              -- cpu time
                           p_n_calls    PLS_INTEGER,         -- number of calls
                           p_ela_self   NUMBER DEFAULT 0,    -- elapsed time for self timer
                           p_cpu_self   NUMBER DEFAULT 0) IS -- cpu time for self timer
BEGIN
  Utils.Pr_List_As_Line (
                L1_chr_arr (RPad (p_timer, p_head_len),
                      Form_Time (p_ela),
                      Form_Time (0.01*(p_cpu)),
                      Form_Calls (p_n_calls),
                      Form_Time (p_ela/p_n_calls, 5),
                      Form_Time (0.01*(p_cpu/p_n_calls), 5)),
                L1_num_arr (p_head_len, -10, -10, -12, -13, -13));

  IF p_timer != '***' AND p_cpu/p_n_calls < 10 * p_cpu_self AND p_cpu > 100 THEN

    Write_Time_Line ('***', p_head_len, p_ela - p_n_calls*p_ela_self, p_cpu - p_n_calls*p_cpu_self, p_n_calls);

  END IF;

END Write_Time_Line;

/***************************************************************************************************

Write_Times: Write a report of the timings for a given timer set

***************************************************************************************************/
PROCEDURE Write_Times (p_timer_set_ind PLS_INTEGER) IS -- timer set id

  c_self_timer_name CONSTANT VARCHAR2(10) := 'STN';

  l_timer_list          timer_arr := g_timer_set_list (p_timer_set_ind).timer_set.timer_list;
  l_sum_ela             NUMBER := 0;
  l_sum_cpu             NUMBER := 0;
  l_ela_seconds         NUMBER;
  l_head_len            PLS_INTEGER;
  l_self_timer          PLS_INTEGER;
  l_time_ela            NUMBER := 0;
  l_time_cpu            NUMBER := 0;
  l_n_calls             PLS_INTEGER := 0;
  l_n_calls_sum         PLS_INTEGER := 0;
  i                     PLS_INTEGER := 0;
  l_timer_stat_rec      timer_stat_rec;

BEGIN

  g_timer_set_list (p_timer_set_ind).timer_set.prior_time := g_timer_set_list (p_timer_set_ind).timer_set.start_time;
  g_timer_set_list (p_timer_set_ind).timer_set.prior_time_cpu := g_timer_set_list (p_timer_set_ind).timer_set.start_time_cpu;
  Increment_Time (p_timer_set_ind, 'Total');
  l_timer_list := g_timer_set_list (p_timer_set_ind).timer_set.timer_list;

  Utils.Heading ('Timer Set: ' || g_timer_set_list (p_timer_set_ind).timer_set.timer_set_name ||
        ', Constructed at ' || To_Char (g_timer_set_list (p_timer_set_ind).timer_set.start_time, Utils.c_datetime_fmt) ||
        ', written at ' || To_Char (SYSDATE, Utils.c_time_fmt));
  l_head_len := 7;
  FOR i IN 1..l_timer_list.COUNT LOOP
    IF Length (l_timer_list(i).name) > l_head_len THEN
      l_head_len := Length (l_timer_list(i).name);
    END IF;
  END LOOP;

  l_self_timer := Construct ('Self');
  FOR i IN 1..1000 LOOP
    Increment_time (l_self_timer, c_self_timer_name);
  END LOOP;
  l_timer_stat_rec := Get_Timer_Stats (p_timer_set_ind => l_self_timer, p_timer_name => c_self_timer_name);
  Destroy (l_self_timer);
  Utils.Write_log ('[Timer timed: Elapsed (per call): ' || LTrim (Form_Time (l_timer_stat_rec.ela_secs)) || ' (' || LTrim (Form_Time (l_timer_stat_rec.ela_secs/l_timer_stat_rec.calls, 6)) ||
      '), CPU (per call): ' || LTrim (Form_Time (l_timer_stat_rec.cpu_secs)) || ' (' || LTrim (Form_Time(l_timer_stat_rec.cpu_secs/l_timer_stat_rec.calls, 6)) || '), calls: ' || l_timer_stat_rec.calls || ', ''***'' denotes corrected line below]');

  l_time_ela := l_timer_stat_rec.ela_secs/l_timer_stat_rec.calls;
  l_time_cpu := 100*l_timer_stat_rec.cpu_secs/l_timer_stat_rec.calls; -- Get_Timer_Stats converts to seconds, Write_Time_Line assumes csecs

  Write_Header ('Timer', l_head_len);

  FOR i IN 1..l_timer_list.COUNT LOOP

    l_ela_seconds := Utils.Get_Seconds (l_timer_list(i).ela_interval);
    l_sum_ela := l_sum_ela + l_ela_seconds;
    l_sum_cpu := l_sum_cpu + l_timer_list(i).cpu_interval;
    l_n_calls := l_timer_list(i).n_calls;
    l_n_calls_sum := l_n_calls_sum + l_n_calls;

    IF i = l_timer_list.COUNT THEN

      Write_Time_Line ('(Other)', l_head_len, 2*l_ela_seconds - l_sum_ela, 2*l_timer_list(i).cpu_interval - l_sum_cpu, 1);

      Utils.Reprint_Line;
      l_n_calls := l_n_calls_sum;

    END IF;
    Write_Time_Line (l_timer_list(i).name, l_head_len, l_ela_seconds, l_timer_list(i).cpu_interval, l_n_calls, l_time_ela, l_time_cpu);

  END LOOP;
  Utils.Reprint_Line;

END Write_Times;

/***************************************************************************************************

Summary_Times: Write a summary report on all the timer sets for the session

***************************************************************************************************/
PROCEDURE Summary_Times IS
  l_head_len            PLS_INTEGER;
  l_timer               timer_rec;

/***************************************************************************************************

Loop_Sets: Loop over the timer sets, printing the reports on each one. If boolean is set, we are
          looping  only to determine the size of the timer set name column, for subsequent printing

***************************************************************************************************/
  PROCEDURE Loop_Sets (p_sizing BOOLEAN DEFAULT FALSE) IS -- get size of timer set name column?
    i                   PLS_INTEGER;
    l_timer_set_name    VARCHAR2(30);
  BEGIN

    i := g_timer_set_list.FIRST;
    WHILE i IS NOT NULL LOOP

      l_timer_set_name := g_timer_set_list(i).timer_set.timer_set_name;
      IF g_timer_set_list(i).timer_set.timer_set_name IS NOT NULL THEN
        IF p_sizing THEN

          IF Length (l_timer_set_name) > l_head_len THEN
            l_head_len := Length (l_timer_set_name);
          END IF;

        ELSE

          l_timer := g_timer_set_list(i).timer_set.timer_list (g_timer_set_list(i).timer_set.timer_list.COUNT);
          Write_Time_Line (l_timer_set_name, l_head_len, Utils.Get_Seconds (l_timer.ela_interval), l_timer.cpu_interval, l_timer.n_calls);

        END IF;
      END IF;
      i := g_timer_set_list.NEXT (i);

    END LOOP;

  END Loop_Sets;

BEGIN

  IF g_timer_set_list IS NULL THEN
    RETURN;
  END IF;

  l_head_len := 9;
  Loop_Sets (TRUE);
  Utils.Heading ('Timer Set Summary');
  Write_Header ('Timer Set', l_head_len);
  Loop_Sets;

  g_timer_set_list.DELETE;-- seem to need both
  g_timer_set_list := NULL;

END Summary_Times;

END Timer_Set;
/
SHOW ERROR

