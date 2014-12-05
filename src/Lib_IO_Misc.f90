!> @ingroup Library
!> @{
!> @defgroup Lib_IO_MiscLibrary Lib_IO_Misc
!> Library of miscellanea procedures for input/output operations.
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Lib_IO_MiscInterface Lib_IO_Misc
!> Library of miscellanea procedures for input/output operations.
!> @}

!> @ingroup GlobalVarPar
!> @{
!> @defgroup Lib_IO_MiscGlobalVarPar Lib_IO_Misc
!> Library of miscellanea procedures for input/output operations.
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Lib_IO_MiscPublicProcedure Lib_IO_Misc
!> Library of miscellanea procedures for input/output operations.
!> @}

!> Library of miscellanea procedures for input/output operations.
!> This is a library module.
!> @ingroup Lib_IO_MiscLibrary
module Lib_IO_Misc
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                                  ! Integers and reals precision definition.
USE Lib_Strings                                                                   ! Library for strings operations.
USE, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT,& ! Standard output/error logical units.
                                        IOSTAT_END, IOSTAT_EOR                    ! Standard end-of-file/end-of record parameters.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
save
private
public:: stdout,stderr,iostat_end,iostat_eor
public:: Get_Unit
public:: get_extension,set_extension
public:: read_file_as_stream
public:: lc_file
public:: File_Not_Found
public:: Dir_Not_Found
public:: inquire_file
public:: inquire_dir
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> @ingroup Lib_IO_MiscGlobalVarPar
integer(I4P), public, parameter:: err_file_not_found      = 20100 !< File not found error ID.
integer(I4P), public, parameter:: err_directory_not_found = 20101 !< Directory not found error ID.
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Lib_IO_MiscPublicProcedure
  !> @{
  !> @brief The Get_Unit function returns a free logic unit for opening a file. The unit value is returned by the function, and also
  !> by the optional argument "Free_Unit". This allows the function to be used directly in an open statement like:
  !> open(unit=Get_Unit(myunit),...) ; read(myunit)...
  !> If no units are available, -1 is returned.
  integer function Get_Unit(Free_Unit)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer, intent(OUT), optional:: Free_Unit !< Free logic unit.
  integer::                        n1        !< Counter.
  integer::                        ios       !< Inquiring flag.
  logical::                        lopen     !< Inquiring flag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Get_Unit = -1
  n1=1
  do
    if ((n1/=stdout).AND.(n1/=stderr)) then
      inquire (unit=n1,opened=lopen,iostat=ios)
      if (ios==0) then
        if (.NOT.lopen) then
          Get_Unit = n1 ; if (present(Free_Unit)) Free_Unit = Get_Unit
          return
        endif
      endif
    endif
    n1=n1+1
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Get_Unit

  !> @brief Procedure for extracting the extension of a filename.
  !> @note The leading and trealing spaces are removed from the file name.
  elemental function get_extension(filename)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: filename      !< File name.
  character(len=len(filename)):: get_extension !< Extension of input file Name.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  get_extension = trim(adjustl(filename(index(filename,'.',back=.true.)+1:)))
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction get_extension

  !> @brief Procedure for setting the extension of a filename.
  !> @note The leading and trealing spaces are removed from the file name.
  elemental function set_extension(filename,extension) result(newfilename)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN)::  filename    !< File name.
  character(len=*), intent(IN)::  extension   !< Extension to be imposed.
  character(len=:), allocatable:: newfilename !< New file name.
  integer(I4P)::                  i           !< Counter.
  character(1)::                  dot         !< Doc caracter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  dot=''
  if (get_extension(trim(adjustl(filename)))/=trim(adjustl(extension))) then
    i = index(filename,'.',back=.true.)
    if (i==0) then
      i   = len(filename)
      dot = '.'
    endif
    newfilename = filename(:i)//trim(dot)//trim(adjustl(extension))
    newfilename = trim(adjustl(newfilename))
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction set_extension

  !> @brief Procedure for reading a file as single characters stream.
  subroutine read_file_as_stream(pref,iostat,iomsg,delimiter_start,delimiter_end,filename,stream)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional,        intent(IN)::  pref            !< Prefixing string.
  integer(I4P), optional,        intent(OUT):: iostat          !< IO error.
  character(*), optional,        intent(OUT):: iomsg           !< IO error message.
  character(*), optional,        intent(IN)::  delimiter_start !< Delimiter from which start the stream.
  character(*), optional,        intent(IN)::  delimiter_end   !< Delimiter to which end the stream.
  character(*),                  intent(IN)::  filename        !< File name.
  character(len=:), allocatable, intent(OUT):: stream          !< Output string containing the file data as a single stream.
  logical::                                    is_file         !< Flag for inquiring the presence of the file.
  integer(I4P)::                               unit            !< Unit file.
  integer(I4P)::                               iostatd         !< IO error.
  character(500)::                             iomsgd          !< IO error message.
  character(len=:), allocatable::              prefd           !< Prefixing string.
  character(1)::                               c1              !< Single character.
  character(len=:), allocatable::              string          !< Dummy string.
  logical::                                    cstart,cend     !< Flag for stream capturing trigging.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  inquire(file=adjustl(trim(filename)),exist=is_file,iostat=iostatd)
  if (.not.is_file) then
    iostat = File_Not_Found(filename=adjustl(trim(filename)),cpn=prefd//'read_file_as_stream')
    return
  endif
  open(unit=Get_Unit(unit),file=adjustl(trim(filename)),access='STREAM',form='UNFORMATTED',iostat=iostatd,iomsg=iomsgd)
  if (iostatd/=0) then
    write(stderr,'(A)')prefd//' Opening file '//adjustl(trim(filename))//' some errors occurs!'
    write(stderr,'(A)')prefd//iomsgd
    write(stderr,'(A)')prefd//' IOSTAT '//str(n=iostatd)
    return
  endif
  stream = ''
  if (present(delimiter_start).and.present(delimiter_end)) then
    string = ''
    Main_Read_Loop: do
      read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
      if (c1==delimiter_start(1:1)) then
        cstart = .true.
        string = c1
        Start_Read_Loop: do while(len(string)<len(delimiter_start))
          read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
          string = string//c1
          if (.not.(index(string=delimiter_start,substring=string)>0)) then
            cstart = .false.
            exit Start_Read_Loop
          endif
        enddo Start_Read_Loop
        if (cstart) then
          cend = .false.
          stream = string
          do while(.not.cend)
            read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
            if (c1==delimiter_end(1:1)) then ! maybe the end
              string = c1
              End_Read_Loop: do while(len(string)<len(delimiter_end))
                read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
                string = string//c1
                if (.not.(index(string=delimiter_end,substring=string)>0)) then
                  stream = stream//string
                  exit End_Read_Loop
                elseif (len(string)==len(delimiter_end)) then
                  cend = .true.
                  stream = stream//string
                  exit Main_Read_Loop
                endif
              enddo End_Read_Loop
            else
              stream = stream//c1
            endif
          enddo
        endif
      endif
    enddo Main_Read_Loop
  else
    Read_Loop: do
      read(unit=unit,iostat=iostatd,iomsg=iomsgd,end=10)c1
      stream = stream//c1
    enddo Read_Loop
  endif
  10 close(unit)
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine read_file_as_stream

  !> @brief Function for calculating the number of lines (records) of a sequential file.
  !>@return \b n integer(I4P) variable
  function lc_file(filename) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: filename ! File name.
  integer(I4P)::             n        ! Number of lines (records).
  logical(4)::               is_file  ! Inquiring flag.
  character(11)::            fileform ! File format: FORMATTED or UNFORMATTED.
  integer(I4P)::             unitfile ! Logic unit.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  inquire(file=adjustl(trim(filename)),exist=is_file,form=fileform) ! Verifing the presence of the file.
  if (.NOT.is_file) then                                            ! File not found.
    n = -1_I4P                                                      ! Returning -1.
  else                                                              ! File found.
    n = 0_I4P                                                       ! Initializing number of records.
    open(unit   = Get_Unit(unitfile),      &
         file   = adjustl(trim(filename)), &
         action = 'READ',                  &
         form   = adjustl(trim(Upper_Case(fileform))))              ! Opening file.
    select case(adjustl(trim(Upper_Case(fileform))))
    case('FORMATTED')
      do
        read(unitfile,*,end=10)                                     ! Reading record.
        n = n + 1_I4P                                               ! Updating number of records.
      enddo
    case('UNFORMATTED')
      do
        read(unitfile,end=10)                                       ! Reading record.
        n = n + 1_I4P                                               ! Updating number of records.
      enddo
    endselect
    10 continue
    close(unitfile)                                                 ! Closing file.
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction lc_file

  !> @brief Procedure for printing to stderr a "file not found error".
  function File_Not_Found(stderrpref,filename,cpn) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN):: stderrpref !< Prefixing string for stderr outputs.
  character(*),           intent(IN):: filename   !< Name of file.
  character(*),           intent(IN):: cpn        !< Calling procedure name.
  integer(I4P)::                       err        !< Error trapping flag: 0 no errors, >0 error occurs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(stderrpref)) then
    write(stderr,'(A)')stderrpref//' File '//adjustl(trim(filename))//' Not Found!'
    write(stderr,'(A)')stderrpref//' Calling procedure "'//adjustl(trim(cpn))//'"'
  else
    write(stderr,'(A)')            ' File '//adjustl(trim(filename))//' Not Found!'
    write(stderr,'(A)')            ' Calling procedure "'//adjustl(trim(cpn))//'"'
  endif
  err = err_file_not_found
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction File_Not_Found

  !> @brief Subroutine for printing to stderr a "directory not found error".
  function Dir_Not_Found(stderrpref,dirname,cpn) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN):: stderrpref !< Prefixing string for stderr outputs.
  character(*),           intent(IN):: dirname    !< Name of directory.
  character(*),           intent(IN):: cpn        !< Calling procedure name.
  integer(I4P)::                       err        !< Error trapping flag: 0 no errors, >0 error occurs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(stderrpref)) then
    write(stderr,'(A)')stderrpref//' Directory '//adjustl(trim(dirname))//' Not Found!'
    write(stderr,'(A)')stderrpref//' Calling procedure "'//adjustl(trim(cpn))//'"'
  else
    write(stderr,'(A)')            ' Directory '//adjustl(trim(dirname))//' Not Found!'
    write(stderr,'(A)')            ' Calling procedure "'//adjustl(trim(cpn))//'"'
  endif
  err = err_directory_not_found
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Dir_Not_Found

  !> @brief Procedure for inquiring the presence of a file.
  !> @note The leading and trealing spaces are removed from the directory name.
  subroutine inquire_file(cpn,pref,iostat,iomsg,file)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  cpn     !< Calling procedure name.
  character(*), optional, intent(IN)::  pref    !< Prefixing string.
  integer(I4P), optional, intent(OUT):: iostat  !< IO error.
  character(*), optional, intent(OUT):: iomsg   !< IO error message.
  character(*),           intent(IN)::  file    !< Name of the file.
  integer(I4P)::                        iostatd !< IO error.
  character(500)::                      iomsgd  !< IO error message.
  character(len=:), allocatable::       prefd   !< Prefixing string.
  character(len=:), allocatable::       cpnd    !< Calling procedure name.
  logical::                             is_file !< Flag for inquiring the presence of file.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  cpnd  = 'inquire_file' ; if (present(cpn )) cpnd  = cpn
  prefd = ''             ; if (present(pref)) prefd = pref
  inquire(file=trim(file),exist=is_file,iomsg=iomsgd)
  if (.not.is_file) then
    iostatd = File_Not_Found(stderrpref=prefd,filename=file,cpn=cpnd)
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine inquire_file

  !> @brief Procedure for inquiring the presence of a directory.
  !> @note The leading and trealing spaces are removed from the directory name.
  subroutine inquire_dir(cpn,pref,iostat,iomsg,directory)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  cpn       !< Calling procedure name.
  character(*), optional, intent(IN)::  pref      !< Prefixing string.
  integer(I4P), optional, intent(OUT):: iostat    !< IO error.
  character(*), optional, intent(OUT):: iomsg     !< IO error message.
  character(*),           intent(IN)::  directory !< Name of the directory.
  integer(I4P)::                        iostatd   !< IO error.
  character(500)::                      iomsgd    !< IO error message.
  character(len=:), allocatable::       prefd     !< Prefixing string.
  character(len=:), allocatable::       cpnd      !< Calling procedure name.
  integer(I4P)::                        unit      !< Unit file.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  cpnd  = 'inquire_dir' ; if (present(cpn )) cpnd  = cpn
  prefd = ''            ; if (present(pref)) prefd = pref
  ! Creating a test file in the directory for inquiring its presence.
  open(unit=Get_Unit(unit),file=adjustl(trim(directory))//'ExiSt.'//prefd,iostat=iostatd,iomsg=iomsgd)
  ! Deletig the test file if successfully created.
  if (iostatd==0_I4P) then
    close(unit,status='DELETE',iomsg=iomsgd)
  else
    iostatd = Dir_Not_Found(stderrpref=prefd,dirname=directory,cpn=cpnd)
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine inquire_dir
  !> @}
endmodule Lib_IO_Misc
