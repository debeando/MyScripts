delay=60
cmd="mysql -u monitor -pmonitor -e 'show slave status\G' | grep Seconds_Behind_Master | awk '{print \$2}'"
while sleep $delay; do
  eval $cmd
done | awk -v delay=$delay '
{
   passed += delay;
   if (count%10==0)
      printf("s_behind d_behind   c_sec_s   eta_d | O_c_sec_s O_eta_d O_eta_h\n");
   if (prev==NULL){
      prev = $1;
      start = $1;
   }
   speed = (delay-($1-prev))/delay;
   o_speed = (start-($1-passed))/passed
   if (speed == 0)    speed_d = 1;
     else             speed_d = speed;
   eta = $1/speed_d;
   if (eta<0)         eta = -86400;
   o_eta = $1/o_speed;
   printf("%8d %8.6f %9.3f %7.3f | %9.3f %7.3f %7.2f\n",
      $1, $1/86400, speed, eta/86400, o_speed, o_eta/86400, o_eta/3600);
   prev=$1;
   count++;
}'

# s_behind  – current Seconds_Behind_Master value
# d_behind  – number of days behind based on current s_behind
# c_sec_s   – how many seconds per second were caught up during last interval
# eta_d     – this is ETA based on last interval
# O_c_sec_s – overall catch-up speed in seconds per second
# O_eta_d   – ETA based on overall catch-up speed (in days)
# O_eta_h   – same like previous but in hours
