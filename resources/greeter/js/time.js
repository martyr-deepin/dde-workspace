
    $(function(){

      setInterval("GetTime()",1000);

    })

    

    function GetTime()

    {

      var mon,day,now,hour,min,ampm,time,str,tz,end,beg,sec;                

      mon=new Array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");              

      day=new Array("Sun","Mon","Tue","Wed","Thu","Fri","Sat");               

      now=new Date(); 

      hour = now.getHours();

      min = now.getMinutes(); 

      sec = now.getSeconds();

      if(hour<10)

      {

         hour="0"+hour;

      }            

      if(min<10)

      {

            min="0"+min;

      } 

      if(sec<10)

      {

         sec="0"+sec;

      } 

      $("#Timer").html("<div class='time01'>"+hour+":"+min+"</div> <div class='time02'>"+day[now.getDay()]+", "+mon[now.getMonth()]+" "+now.getDate()+", "+now.getFullYear() +"</div>");

    }
