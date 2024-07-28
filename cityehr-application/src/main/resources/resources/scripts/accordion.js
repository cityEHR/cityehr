/*
    *********************************************************************************************************
    cityEHR
    accordian.js
    
    JQuery function to implement accordian behaviour on viewNavigationSelection
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    **********************************************************************************************************
*/

$(document).ready(function() {
	 
	//ACCORDION BUTTON ACTION (ON CLICK DO THE FOLLOWING)
	//$this is the <a> element inside the viewNavigationItem
	$('.viewNavigationItem .viewNavigationItemSelect').click(function() {
	
		//REMOVE THE ON CLASS FROM ALL BUTTONS
		$('.viewNavigationItem .viewNavigationItemSelect').removeClass('on');
		
		//RETURNS THE + ICON TO ALL BUTTONS
		$('.viewNavigationStatus').html("+");
		  
		//NO MATTER WHAT WE CLOSE ALL OPEN SLIDES
	 	$('.viewNavigationItem .viewNavigationItemList').slideUp('normal');
	
		//IF THE NEXT SLIDE WASN'T OPEN THEN OPEN IT
		if($(this).closest('.viewNavigationItem').find('.viewNavigationItemList').is(':hidden') == true) {
			
			//ADD THE ON CLASS TO THE BUTTON
			$(this).addClass('on');
			  
			//OPEN THE SLIDE
			$(this).closest('.viewNavigationItem').find('.viewNavigationItemList').slideDown('normal');
			
			//REPLACE THE + ICON WITH A -
			$(this).find('.viewNavigationStatus').html("-");
		 } 
		  
	});
	  
	$('.viewNavigationItem .viewNavigationItemList').hide();

});
