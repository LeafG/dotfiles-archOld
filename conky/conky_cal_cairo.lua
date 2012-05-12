--[[Calendar Box by wlourf v.1.0 15/05/2010:
Parameters are explained with images on this page :
http://u-scripts.blogspot.com/2010/05/calendar-box.html

This widget draw a calendar in your conky.
You need conky 1.8.0+ to run it. and set theses conky settings:
own_window_transparent yes
own_window_argb_visual yes

In the conky, before TEXT section:
lua_load ~/scripts/calendar/calendar.lua
lua_draw_hook_pre calendar_box

]]

require 'cairo'

function conky_calendar_box()

--settings are set in this table, cal_settings, 4 parameters are mandatory :
--w,y,font and font_size,
--others parameters are optionals

	cal_settings={
		{
		x=1,		--x of top left corner, relative to conky window
		y=1,		--y of top left corner, relative to conky window
		font="Verdana",		--font to use
		font_size=14,		--font size to use
			
		month_format="%B %Y", --month format, see http://www.lua.org/pil/22.1.html for available formats, default="%B"
		days_number=3,		  --number of letters for days (monday ...), default = 1

		days_position="t",		-- position of boxes "Days" (t/b) top or bottom, default=t
		month_position="l",		-- position of box "Month" (t/b/l/r) top, bottom, left or right, default=t
		two_digits=false,		-- display numbers with two digits (true/false), default=false
		alignment="c",			-- alignment of days numbers (c/r/l), default= c
			
		month_offset=0,		-- month offset relative to actual month, default=0 (offset +1 is next month, offset -1 is last month)
		
		display_others_days=true, --display days numbers of previous and next months, default=true
		
		hpadding=5,		--horizontal space beetween border and text, default=2 pixels
		vpadding=3,		--vertical space beetween border and text, default=2 pixels
		border=1,		--border size, default=0 pixels
		gap=5,			--space betwwen 2 boxes, default=2 pixels
		radius=5,		--radius of corners, default=0 pixels
	
		--colors tables
		--format for boxes  {color1, Alpha (transparency, between 0 and 1), border:  color, Alpha (transparency)}
		--format for texts  {color1, Alpha (transparency)}

		colBox = {0x004000,0.4,0xC0C0C0,0.8},                      --color of standard box
		colBoxText  ={0xFFFFFF,1},    					--color of text numbers
		colBoxTextOM = {0xC0C0C0,1},   				--color of numbers for other month
	
		colDays = {0x004000,1,0x000080,1},    --color of boxes "Days" (Monday ...)
		colDaysText  ={0xFFFF00,1},     				--color of days (Monday ...)
	
		colBoxTD  = {0xC0C0C0,1,0x7F2000,1},  --color of box "Today"
		colBoxTextTD = {0x000000,1},	   				--color of text "today"
	
		colBoxWE  = {0x7F2000,1,0x000080,1}, --color of box weekend days
		colBoxTextWE = {0xFFFF00,1},	   				--color of text weekend days
	
		colMonth = {0x004000,1,0x00FF00,1},   --color of box "Month"
		colMonthText  = {0xFFFF00,1},   					--color of text "Month"
	
		display_info_box=true,			--affiche la boite info (default=false)
		file_info="/tmp/info.txt",		--read first line of this file and display it box "info"
										--if file not found, use calendar.txt
		colInfo = {0x004000,1,0x00FF00,1}, --color of box "info"
		colInfoText = {0xFFFF00,1},						--color of text "info"
		info_position="t",   			--position of box info  (t/b/l/r) top, bottom, left or right, default=b
		display_empty_info_box=true,	--if no info to display , display or not info the box, default=false	
		},

	}

--FIN DES PARAMETRES ------------------


	if conky_window == nil then return end
	--if tonumber(conky_parse("$updates"))<3 then return end
	local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width-20, conky_window.height-20)
	cr = cairo_create (cs)

	
    for i,v in pairs(cal_settings) do
        x,y=draw_calendar(v)
	end
	    
	cairo_destroy(cr)
	cairo_surface_destroy(cs)

end

function draw_square(cr,x,y,width,height,radius)
	local degrees = math.pi / 180.0
	radius=tonumber(radius)

	cairo_new_sub_path (cr);
	if radius>0 then
		cairo_arc (cr, x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
		cairo_arc (cr, x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
		cairo_arc (cr, x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
		cairo_arc (cr, x + radius, y+ radius, radius, 180 * degrees, 270 * degrees);
	else
		cairo_rectangle(cr,x,y,width,height)
	end
	cairo_close_path (cr);

	return 
end


function rgb_to_r_g_b(colour,alpha)
	return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

--[[
function hex_to_rgb(color)
  -- --------------------------------------------------------------------------
    http://gristle.tripod.com/hexconv.html#hex-rgb
    The formula from RGB to Hex and vice versa:
    for RGB to hex divide each vlue by 16. 
    R / 16 = x + y/16 (remainder)
    G / 16 = x1 + y1/16
    B / 16 = x2 + y2/16
   all in base 16. Then concatenate the results: xy x1y1 x2y2
   Example RGB:  80, 6, 143, is:
      80/16 =   5 + 0/16,
      6/16 =     0 + 6/16, and
      143/16 = 8 + 15/16;
   giving 50 06 8F (15 in base 16 is F) or:
       50068F.
    for hex to RGB for each pair from the hex number: multiply the first  by 16 and add the 2nd. 
    Example: B60023
    B6, 00, 23 (B in base 16 is 11 in base 10)
    11*16 + 6 = 182
    0 * 16 + 0 = 0
    2 * 16 + 3 = 35
   RGB = 182, 0, 35
   RGB in the Cairo functions is a number between 0 - 1, so, the R, G, B need to be divided by 255
  -- --------------------------------------------------------------------------

	local c1 = string.format ("%6x",color)

	local t = {} 

	t[1]= string.sub(c1,1,1)
	t[2]= string.sub(c1,2,2)
	t[3]= string.sub(c1,3,3)
	t[4]= string.sub(c1,4,4)
	t[5]= string.sub(c1,5,5)
	t[6]= string.sub(c1,6,6)

	for i=1,6 do
		if t[i] == "" or  t[i] == nil or t[i] == " "  then t[i] = 0 end
		if t[i] == "a" then t[i] = 10 end
		if t[i] == "b" then t[i] = 11 end
		if t[i] == "c" then t[i] = 12 end
		if t[i] == "d" then t[i] = 13 end
		if t[i] == "e" then t[i] = 14 end
		if t[i] == "f" then t[i] = 15 end
	end

	local R = t[1]*16 + t[2]
        local G = t[3]*16 + t[4]
        local B = t[5]*16 + t[6]

        local r1,g1,b1 =  R/255, G/255, B/255
--	print ("c1 in hex2rgb is: ".. c1.. " rgb for it is: ".. R,G,B.. " rgb is: ".. r1,g1,b1)

--	return R,G,B
	return r1,g1,b1

end
]]

function create_pattern(cr,x,y,w,h,tCol,radius)

	local color1,alpha1=tCol[1],tCol[2]
--	local  r,g,b = hex_to_rgb(tCol[1])
	local  r,g,b = rgb_to_r_g_b(tCol[1],tCol[2])
	
--	print (" create_pattern, alpha, r,g,b and color1 are: ".. alpha1, r,g,b, color1)

        cairo_set_source_rgba (cr, r,g,b,alpha1) -- color and alpha

end

function draw_frame (x0,y0,width,height,tCol,radius,border)

	cairo_set_operator(cr,CAIRO_OPERATOR_SOURCE)
	create_pattern(cr,x0,y0,width,height,{tCol[3],tCol[4]},radius) -- border
	draw_square(cr,x0,y0,width,height,radius)
	cairo_set_line_width(cr,border)
        cairo_stroke (cr);

	cairo_set_operator(cr,CAIRO_OPERATOR_OVER)
	create_pattern(cr,x0,y0,width,height,{tCol[1],tCol[2]}) -- inner rectangle
	draw_square(cr,x0+border,y0+border,width-border*2,height-border*2,radius)
	cairo_fill (cr)
--[[
	cairo_set_operator(cr,CAIRO_OPERATOR_OVER)
	create_pattern(cr,x0,y0,width,height,{tCol[1],tCol[2]})  
	draw_square(cr,x0+border,y0+border,width-border*2,height-border*2,radius)
	cairo_fill (cr)
]]

end

function string:split(delimiter)
--source for the split function : http://www.wellho.net/resources/ex.php4?item=u108/split
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end


function draw_calendar(t)
	local te=cairo_text_extents_t:create()
	if t.font==nil or t.x==nil or t.y == nil or t.font_size == nil then
		print ("Error in settings")
		return 
	end
	
	--check values or set default values
	x0,y0=t.x,t.y
	if t.two_digits then str_format="%02d" else str_format="%d" end
	if t.month_format==nil then t.month_format = "%B" end
	if t.hpadding==nil then t.hpadding=2 end
	if t.vpadding==nil then t.vpadding=2 end
	if t.border==nil then t.border=0 end		
	if t.month_offset==nil then t.month_offset=0 end
	if t.gap==nil then t.gap=2 end
	if t.radius==nil then t.radius=0 end
	if t.days_number==nil then t.days_number=1 end
	if t.display_others_days==nil then t.display_others_days=true end
	if t.display_info_box == nil then t.display_info_box=false end
	if t.display_empty_info_box == nil then t.display_empty_info_box=false end

	local alignment ="c"
	for i,v in ipairs({"l","c","r"}) do 
		if v==t.alignment then alignment=v end
	end
	local month_position="t"
	for i,v in ipairs({"t","b","l","r"}) do 
		if v==t.month_position then month_position=v end
	end
	local days_position="t"
	for i,v in ipairs({"t","b","l","r"}) do 
		if v==t.days_position then days_position=v end
	end
	local info_position="b"
	for i,v in ipairs({"t","b","l","r"}) do 
		if v==t.info_position then info_position=v end
	end
	
	function table.copy(t)
		local t2 = {}
		for k,v in pairs(t) do
			t2[k] = v
		end
		return t2
	end

	if t.colBox ~= nil and #t.colBox ~=4 then t.colBox=nil end
	if t.colDays ~= nil and #t.colDays ~=4 then t.colDays=nil end	
	if t.colMonth ~= nil and#t.colMonth ~=4 then t.colMonth=nil end	
	if t.colBoxTD ~= nil and #t.colBoxTD ~=4 then t.colBoxTD=nil end
	if t.colBoxWE ~= nil and #t.colBoxWE ~=4 then t.colBoxWE=nil end
	if t.colInfo ~= nil and #t.colInfo ~=4 then t.colInfo=nil end	
	if t.colBoxText ~= nil and #t.colBoxText ~= 2 then t.colBoxText=nil end
	if t.colBoxTextOM ~= nil and #t.colBoxTextOM ~=2 then t.colBoxText=nil end
	if t.colBoxTextTD ~= nil and #t.colBoxTextTD ~= 2 then t.colBoxTextTD=nil end
	if t.colBoxTextWE ~= nil and #t.colBoxTextWE ~= 2 then t.colBoxTextWE=nil end
		
	if t.colDaysText ~= nil and #t.colDaysText ~= 2 then t.colDaysText=nil end
	if t.colMonthText ~= nil and #t.colMonthText ~= 2 then t.colMonthText=nil end
	if t.colInfoText ~= nil and #t.colInfoText ~= 2 then t.colInfoText=nil end	

	if t.colBox == nil then t.colBox = {0x000000,0,0xFFFFFF,0} end
	if t.colDays == nil then t.colDays = table.copy(t.colBox) end
	if t.colMonth == nil then t.colMonth = table.copy(t.colBox) end
	if t.colInfo == nil then t.colInfo = t.colBox end
	if t.colBoxTD == nil then t.colBoxTD = {t.colBox[2],t.colBox[1],t.colBox[3],t.colBox[4]}end
	if t.colBoxWE == nil then t.colBoxWE = t.colBox end
	if t.colBoxText == nil	then t.colBoxText = {0x000000,1} end
	if t.colBoxTextOM == nil then t.colBoxTextOM = {0x00000,0.2} end
	if t.colBoxTextTD == nil then t.colBoxTextTD = {0x0000FF,1} end
	if t.colDaysText == nil	then t.colDaysText = {0x999999,1} end
	if t.colMonthText == nil	then t.colMonthText = {0x333333,1} end
	if t.colInfoText == nil	then t.colInfoText = {0x333333,1} end
	
	--calculate maximum size of a square
	local maxSide=0
	cairo_select_font_face(cr, t.font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
	cairo_set_font_size(cr,t.font_size)
	for d=1,31 do
		cairo_text_extents (cr,string.format(str_format,d),te)
		maxSide = math.max(maxSide,te.width+te.x_bearing+2*t.hpadding,te.height+te.y_bearing+2*t.vpadding)
	end
	maxSide=maxSide+2*t.border

	

   -- Compute what day it was the first of the month (0=Sunday)
   -- from conky wiki
   dtable = os.date("*t")
   --this month table
   mtable=dtable
   mtable.month=dtable.month+t.month_offset
   mtable = os.date("*t",os.time(mtable))
   day,wday = mtable.day, mtable.wday
   first_day = wday - 1 - (day-1) % 7
   if first_day < 0 then first_day = first_day + 7 end
   
      -- Compute what day it was the first weekend date of the month
   first_weekend = (7 - first_day) % 7

   local txt_month = os.date(t.month_format, os.time(mtable))
   txt_month = string.upper(string.sub(txt_month,1,1)) .. string.sub(txt_month,2)
   
	function get_days_in_month(month, year)
		local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }   
		local d = days_in_month[month]

		-- check for leap year
		if (month == 2) then
			if (math.mod(year,4) == 0) then
				if (math.mod(year,100) == 0)then                
					if (math.mod(year,400) == 0) then                    
						d = 29
					end
				else                
					d = 29
				end
			end
		end

		return d  
	end
	last_day=get_days_in_month(mtable.month, mtable.year)
	
	lpdtable=mtable
    lpdtable.month=lpdtable.month-1
    mtable = os.date("*t",os.time(lpdtable))
    if lpdtable.month==0 then lpdtable.month=12 end
	
    last_p_day=get_days_in_month(lpdtable.month,lpdtable.year)
   	mtable.month=lpdtable.month+1
   	mtable = os.date("*t",os.time(mtable))

	local txt_info=os.date("%H")..":"..os.date("%M")

	--define text for days
	tdays={}
	for i=3,10 do
		table.insert(tdays,os.date("%A", os.time{year=2010, month=1, day=i}))
	end
	for i=1,7 do
		tdays[i]=string.upper(string.sub(tdays[i],1,1)) .. string.sub(tdays[i],2)
		tdays[i]=(string.sub(tdays[i],1,math.max(t.days_number,1)))
	end

	local display_day=true
	--draw numbers boxes
    local flagEnd=0
    d=0
	for r=0,5 do
		if flagEnd>0 then break end
		for c=0,6 do
			d=d+1
			X=x0+c*maxSide+t.gap*c
			Y=y0+r*maxSide+t.gap*r
			if month_position=="t" then	
				Y=Y+maxSide+t.gap 
			elseif month_position=="l" then
				X=X+maxSide+t.gap
			end
			if info_position=="t" then	
				Y=Y+maxSide+t.gap 
			elseif info_position=="l" then
				X=X+maxSide+t.gap
			end

			if days_position=="t" then
				Y=Y+maxSide+t.gap 
			end

							
			--weekend day or not ?
			local flagWE = false
			if d % 7 == 0 then flagWE = true end
--			if (d + first_weekend) % 7 == 0 then flagWE = true end

			--draw frames
			local colorBox=t.colBox
			if flagWE then
				colorBox=t.colBoxWE
			end
			if dtable.day == d-first_day and t.month_offset==0 then
				colorBox=t.colBoxTD
			end
			draw_frame (X,Y,maxSide,maxSide,colorBox,t.radius,t.border)
			
			--format _text
			if d<=first_day  then  									--days before
				create_pattern(cr,X,Y,maxSide,maxSide,t.colBoxTextOM)
				txt_date=last_p_day-first_day+d
				display_day=t.display_others_days
			elseif d-first_day>0 and d-first_day<=last_day then      -- days of the month
				txt_date=d-first_day
				local colorText= t.colBoxText
				if flagWE then
					colorText=t.colBoxTextWE
				elseif txt_date==dtable.day and t.month_offset==0 then
					colorText=t.colBoxTextTD
				end
				create_pattern(cr,X,Y,maxSide,maxSide,colorText)
				
				display_day=true
			else												--days after
				txt_date=d-first_day-last_day
				create_pattern(cr,X,Y,maxSide,maxSide,t.colBoxTextOM)
				display_day=t.display_others_days
			end
			
			--show text or not
			if display_day then
				cairo_text_extents (cr,string.format(str_format,txt_date),te)
				if alignment=="r" then
					delta=maxSide-te.width-te.x_bearing-t.border-t.hpadding
				elseif alignment=="c" then
					delta=(maxSide-te.width)/2-te.x_bearing
				else
					delta=t.border+t.hpadding
				end
				if c==0 or d-first_day==1 then teheight= te.height end
				cairo_move_to(cr,X+delta,Y+(maxSide)/2+teheight/2)
				cairo_show_text(cr,string.format(str_format,txt_date))
			end
			
			if d-first_day>=last_day then
				flagEnd=r
			end
		end

	end
	
	--show days (monday, thuesday ...)
	if days_position=="t" then
		Y=y0
		if month_position=="t" then Y=Y+maxSide+t.gap end
		if info_position=="t" then Y=Y+maxSide+t.gap end
	else
		Y=y0+(flagEnd+1)*(maxSide+t.gap)
	end
	
	deltaX=0
	
	if month_position=="l" then	deltaX=deltaX+maxSide+t.gap end
	if info_position=="l" then	deltaX=deltaX+maxSide+t.gap end	
	flagEnd=flagEnd+1
	for c =0,6 do
		X=x0+c*maxSide+t.gap*c+deltaX
		draw_frame (X,Y,maxSide,maxSide,t.colDays,t.radius,t.border)
		cairo_save(cr)
		cairo_text_extents (cr,tdays[c+1],te)
		local ratio=(maxSide-2*t.border-2*t.hpadding)/(te.width+te.x_bearing + t.border + t.hpadding)
		if ratio>1 then ratio=1 end
		local xm = X+t.hpadding+(maxSide-2*t.hpadding-te.width)/2-te.x_bearing--+t.hpadding/2
		
		local ym = Y+(maxSide+te.height)/2
		if ratio<1 then xm=X+t.border+t.hpadding end
		
		if alignment=="r" then
			delta=maxSide-te.width-te.x_bearing-t.border-t.hpadding
		elseif alignment=="c" then
			delta=(maxSide-te.width)/2-te.x_bearing
		else
			delta=t.border+t.hpadding
		end

		cairo_move_to(cr,xm,ym)
		create_pattern(cr,X,Y,maxSide,maxSide,t.colDaysText)
		cairo_save(cr)
		cairo_scale(cr,ratio,1)
		cairo_show_text(cr,tdays[c+1])
		cairo_restore(cr)	
	end

	function show_big_box(txt,box,position)
		cairo_text_extents (cr,txt,te)
		hbox={ width  = maxSide*7+t.gap*6,  height  = maxSide}
		vbox={ width  = maxSide,  height  = maxSide*(flagEnd+1)+t.gap*flagEnd}
		local deltaY = 0
		local deltaX = 0
	
		if box=="month" then
			tColor=t.colMonth
			tColorText=t.colMonthText
			if info_position=="l" or info_position=="r" then
				hbox={ width  = maxSide*8+t.gap*7,  height = maxSide}
			end
			if info_position=="l" then
				deltaX = (maxSide+t.gap)
			end 
			if info_position=="t"  and month_position=="t" then
				deltaY = (maxSide+t.gap)
			end
			if (month_position=="l" or month_position=="r") and (info_position=="t") then
				deltaY=(maxSide+t.gap)
			end
			if (month_position=="b") and (info_position=="t") then
				deltaY=(maxSide+t.gap)
			end	
		elseif box=="info" then
			tColor=t.colInfo
			tColorText=t.colInfoText
			if month_position=="l" or month_position=="r"then
				hbox={ width  = maxSide*8+t.gap*7,  height  = maxSide}
			end 	
			if month_position=="r" and info_position=="r" then 
				deltaX=(maxSide+t.gap)
			end
			if (month_position=="t") and (info_position=="l" or info_position=="r") then
				deltaY=(maxSide+t.gap)
			end
			if (month_position=="t") and (info_position=="b") then
				deltaY=(maxSide+t.gap)
			end			
			if (month_position=="b") then
				vbox={ width  = maxSide,  height  = maxSide*(flagEnd)+t.gap*(flagEnd-1)}
			end
		else
			return	
		end
	
		if position=="b" then	
			flagEnd=flagEnd+1
			draw_frame (x0,y0+flagEnd*(maxSide+t.gap)+deltaY,hbox.width,hbox.height,tColor,t.radius,t.border)
		elseif position=="l" then
			draw_frame (x0+deltaX,y0+deltaY,vbox.width, vbox.height,tColor,t.radius,t.border)
		elseif position=="r" then
			draw_frame (x0+7*(maxSide+t.gap)+deltaX,y0+deltaY,vbox.width,vbox.height,tColor,t.radius,t.border)
		else
			draw_frame (x0,y0+deltaY,hbox.width,hbox.height,tColor,t.radius,t.border)
		end

		if position=="t" or position=="b" then
			cairo_save(cr)
			local ratio=(hbox.width-2*t.border-2*t.hpadding)/(te.width + te.x_bearing)
			if ratio>1 then ratio=1 end
		
			local xm = x0+hbox.width/2-(te.width/2 + te.x_bearing)
			local ym = y0+hbox.height/2-(te.height/2+ te.y_bearing)
			if ratio<1 then xm=x0+t.border +t.hpadding end
			y1=y0
			if position=="b" then 
				ym = ym + flagEnd*(maxSide+t.gap)
				y1 = y0 + flagEnd*(maxSide+t.gap)
			end
			
			create_pattern(cr,x0,y1 ,hbox.width,hbox.height,tColorText)
			cairo_translate(cr,xm,ym+deltaY)
			cairo_scale(cr,ratio,1)
			cairo_show_text(cr,txt)
			cairo_restore(cr)
		end
	
		if position=="l" or position=="r" then
			cairo_save(cr)
			--ajuster la taille, � faire avec cairo_set_scaled_font ??
			local ratio=(vbox.height-2*t.border-2*t.hpadding)/(te.width + te.x_bearing)
			if ratio>1 then ratio=1 end
		
			local xm = x0+vbox.width/2-(te.height/2 + te.y_bearing)+deltaX
			local ym = y0+vbox.height/2+(te.width/2+ te.x_bearing)
			if ratio<1 then ym= y0 + vbox.height - t.border -t.hpadding end 
			if position=="r" then xm=xm + 7*(maxSide+t.gap) end

			--hum hum ...
			create_pattern(cr,xm-hbox.height+te.height,ym-te.width- te.x_bearing,hbox.height,te.width+ te.x_bearing,tColorText)
			cairo_translate(cr,xm,ym+deltaY)
			cairo_rotate(cr,-math.pi/2)
			cairo_scale(cr,ratio,1)
			cairo_show_text(cr,txt)
			cairo_restore(cr)
		end
	
	end

	local yZ=y0+(flagEnd+1)*(maxSide+t.gap)
	show_big_box(txt_month,"month",month_position)
	if month_position =="t" or  month_position =="b" then yZ=yZ+(maxSide+t.gap) end
	
	if t.display_info_box  then 
		if t.file_info ~= nil then
			local file = io.open(t.file_info,"r")
			if file ~= nil then txt_info = file:read("*l") end
		end
		show_big_box(txt_info,"info",info_position)
		if info_position =="t" or  info_position =="b" then yZ=yZ+(maxSide+t.gap) end
	end
	
	return x0,yZ--X,Y
end


