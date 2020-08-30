function status = store_filter (file_name,Num,Den)
##
##  status=store_filter(filename, Num, Den)
##
## Author: Dr. Carlos Romero Pérez
##
## Description
## ===========
## This funtion stores the Numerator and Denominator of a filter
## in a file. The funtion allows the user to select the path where
## to store the file.
##
## The format of the file is a hheadr file for cpp or c standard 
## ANSI C file.
##
## Function returns true when file has been successfully created or
## false if not
##
## Trace
## 27/07/2020: First edition
## 10/08/2020: filename argument has not the suffix. The function creates a
##              header file intead of a Cpp file.
##
##
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.
##
    
## Verification of inputs correctness

status=ischar(file_name);

if status==false
  disp("Incorrect file name. Storage action aborted\n");
  return;
endif

  
status=isnumeric(Num);
if status==false
  disp("Incorrect numerator coefficients vector. Must be numeric");
else
  status=isvector(Num);
  if status==false
    disp("Numerator must be a vector");
  endif
  if rows(Num)>1
    Num=Num';     # Vector are formatted to row vectors
  endif
endif
  
if status==true 
  status=isnumeric(Den);
  if status==false
    disp("Incorrect denominator coefficients vector. Must be numeric");
  else
    status=isvector(Den);
    if status==false
      disp("Denominator must be a vector");
    endif
    if rows(Den)>1
      Den=Den';     # Vector are formatted to row vectors
    endif
  endif
endif
  
if status==true 
  ## Definition of header for C/Cpp files
  uppername=toupper(file_name);
  header=sprintf("/**\n*\t%s.h\n*\n*\t\\author Dr. Carlos Romero Pérez\n",file_name);
  datefile=sprintf("*\t\\date %s \n",date());
  description=sprintf("*\t Description\n*\t==\n*\t Filter coefficients\n*\n*/\n");
  conditional=sprintf("#ifndef _%s_\n#define\t_%s_\n",uppername,uppername);
  endconditional=sprintf("#endif\n");
  
  # Generation of the full path+file name and opening file
  pathfile=uigetdir("","Select folder destination");    ## Select destination path
   
  path_name=strcat(pathfile,file_name,".h");
  
  namevector=file_name;
  
  [fid,msg]=fopen(path_name,"wt");
    
  if fid==-1
    status=false;
    disp(msg);
  else
    #Write data into file
    fprintf(fid,header);
    fprintf(fid,datefile);
    fprintf(fid,description);
    fprintf(fid,conditional);
    ncoef=length(Num);
    fprintf(fid,"const double B%s[]={",namevector);
      
    for ind=1:ncoef
      fprintf(fid,"%.15f",Num(ind));
      if ind<ncoef
        fprintf(fid,",");
      endif
      
    endfor
    fprintf(fid,"};\n");
     
    ncoef=length(Den);
    fprintf(fid,"const double A%s[]={",namevector);
      
    for ind=1:ncoef
      fprintf(fid,"%.15f",Den(ind));
      if ind<ncoef
        fprintf(fid,",");
      endif
      
    endfor
    fprintf(fid,"};\n");
    
    fprintf(fid,endconditional);
      
    if fclose(fid)==0
      disp("File successfully created");
    else
      disp("Error creating the file");
      statis=false;
    endif 
  endif
      
endif
  
return;
  
endfunction
