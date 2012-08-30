!> @ingroup PublicProcedure
!> @{
!> @defgroup Lib_Fluxes_DiffusivePublicProcedure Lib_Fluxes_Diffusive
!> @}

!> @ingroup PrivateProcedure
!> @{
!> @defgroup Lib_Fluxes_DiffusivePrivateProcedure Lib_Fluxes_Diffusive
!> @}

!> This module contains the definition of procedures for computing diffusive fluxes (parabolic operator).
!> This is a library module.
!> @todo \b DocComplete: Complete the documentation of internal procedures
!> @ingroup Library
module Lib_Fluxes_Diffusive
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                           ! Integers and reals precision definition.
USE Data_Type_Conservative, init_cons=>init, set_cons=>set ! Definition of Type_Conservative.
USE Data_Type_Globals                                      ! Definition of Type_Global and Type_Block.
USE Data_Type_Primitive, init_prim=>init, set_prim=>set    ! Definition of Type_Primitive.
USE Data_Type_Tensor, set_ten=>set                         ! Definition of Type_Tensor.
USE Data_Type_Vector, set_vec=>set                         ! Definition of Type_Vector.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
save
private
public:: fluxes_diffusive
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> Subroutine for computing interfaces diffusive fluxes (parabolic operator).
  subroutine fluxes_diffusive(global,block,i,j,k,dir,F)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Global),       intent(IN)::    global !< Global-level data.
  type(Type_Block),        intent(IN)::    block  !< Block-level data.
  integer(I_P),            intent(IN)::    i,j,k  !< Interface indexes.
  character(1),            intent(IN)::    dir    !< Direction of fluxes ('i','j','k').
  type(Type_Conservative), intent(INOUT):: F      !< Diffusive fluxes at the interface.
  type(Type_Vector):: NFS(1:6) !< Normals, with interfaces area as module, of the 6 hexahedron's faces of finite
                               !< volume centered at interface i,j,k.
  type(Type_Vector):: vel(1:6) !< Velocity vector at interfaces of finite volume centered at interface i,j,k.
  type(Type_Tensor):: tau      !< Shear stress tensor.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! computing metrics of finite volume centered at interface i,j,k
  call fv_interface_metrics(mesh=block%mesh)
  ! computing velocity vector at the interfaces of the finite volume centered at interface i,j,k
  call fv_interface_velocity(fluid=block%fluid)
  ! computing the shear stress tensor at interface i,j,k
  call shear_stress()
  ! computing the diffusive fluxes
  select case(dir)
  case('i')
    F%rs = 0._R_P
    F%rv = -(tau.dot.block%mesh%NFi(i,j,k))
    F%re = -((tau.dot.(0.5_R_P*(block%fluid%P(i,j,k)%v+block%fluid%P(i+1,j,k)%v))).dot.block%mesh%NFi(i,j,k))
  case('j')
    F%rs = 0._R_P
    F%rv = -(tau.dot.block%mesh%NFj(i,j,k))
    F%re = -((tau.dot.(0.5_R_P*(block%fluid%P(i,j,k)%v+block%fluid%P(i,j+1,k)%v))).dot.block%mesh%NFj(i,j,k))
  case('k')
    F%rs = 0._R_P
    F%rv = -(tau.dot.block%mesh%NFk(i,j,k))
    F%re = -((tau.dot.(0.5_R_P*(block%fluid%P(i,j,k)%v+block%fluid%P(i,j,k+1)%v))).dot.block%mesh%NFk(i,j,k))
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  contains
    !> Subroutine for computing the metrics (normals and interfaces area) of finite volume centered at interface i,j,k.
    !> Such a 'shifted' finite volume is used in computing partial derivative by means of finite volume approach (using Green's
    !> theorem).
    !> @note The computed metrics is stored as normals to the 6 hexahedron faces of the shifted finite volume. Each normal has
    !> module equal to its face area.
    !> @return \b NFS(1:6) Type_Vector array.
    subroutine fv_interface_metrics(mesh)
    !-------------------------------------------------------------------------------------------------------------------------------
    implicit none
    type(Type_Mesh_Block), intent(IN):: mesh !< Block-level mesh data.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    select case(dir)
    case('i')
      NFS(1) = 0.5_R_P*(mesh%Si(i,j  ,k  )*mesh%NFi(i,j  ,k  ) + mesh%Si(i-1,j  ,k  )*mesh%NFi(i-1,j  ,k  ))
      NFS(2) = 0.5_R_P*(mesh%Si(i,j  ,k  )*mesh%NFi(i,j  ,k  ) + mesh%Si(i+1,j  ,k  )*mesh%NFi(i+1,j  ,k  ))
      NFS(3) = 0.5_R_P*(mesh%Sj(i,j-1,k  )*mesh%NFj(i,j-1,k  ) + mesh%Sj(i+1,j-1,k  )*mesh%NFj(i+1,j-1,k  ))
      NFS(4) = 0.5_R_P*(mesh%Sj(i,j  ,k  )*mesh%NFj(i,j  ,k  ) + mesh%Sj(i+1,j  ,k  )*mesh%NFj(i+1,j  ,k  ))
      NFS(5) = 0.5_R_P*(mesh%Sk(i,j  ,k-1)*mesh%NFk(i,j  ,k-1) + mesh%Sk(i+1,j  ,k-1)*mesh%NFk(i+1,j  ,k-1))
      NFS(6) = 0.5_R_P*(mesh%Sk(i,j  ,k  )*mesh%NFk(i,j  ,k  ) + mesh%Sk(i+1,j  ,k  )*mesh%NFk(i+1,j  ,k  ))
    case('j')
      NFS(1) = 0.5_R_P*(mesh%Sj(i  ,j,k  )*mesh%NFj(i  ,j,k  ) + mesh%Sj(i  ,j-1,k  )*mesh%NFj(i  ,j-1,k  ))
      NFS(2) = 0.5_R_P*(mesh%Sj(i  ,j,k  )*mesh%NFj(i  ,j,k  ) + mesh%Sj(i  ,j+1,k  )*mesh%NFj(i  ,j+1,k  ))
      NFS(3) = 0.5_R_P*(mesh%Sk(i  ,j,k-1)*mesh%NFk(i  ,j,k-1) + mesh%Sk(i  ,j+1,k-1)*mesh%NFk(i  ,j+1,k-1))
      NFS(4) = 0.5_R_P*(mesh%Sk(i  ,j,k  )*mesh%NFk(i  ,j,k  ) + mesh%Sk(i  ,j+1,k  )*mesh%NFk(i  ,j+1,k  ))
      NFS(5) = 0.5_R_P*(mesh%Si(i-1,j,k  )*mesh%NFi(i-1,j,k  ) + mesh%Si(i-1,j+1,k  )*mesh%NFi(i-1,j+1,k  ))
      NFS(6) = 0.5_R_P*(mesh%Si(i  ,j,k  )*mesh%NFi(i  ,j,k  ) + mesh%Si(i  ,j+1,k  )*mesh%NFi(i  ,j+1,k  ))
    case('k')
      NFS(1) = 0.5_R_P*(mesh%Sk(i  ,j  ,k)*mesh%NFk(i  ,j  ,k) + mesh%Sk(i  ,j  ,k-1)*mesh%NFk(i  ,j  ,k-1))
      NFS(2) = 0.5_R_P*(mesh%Sk(i  ,j  ,k)*mesh%NFk(i  ,j  ,k) + mesh%Sk(i  ,j  ,k+1)*mesh%NFk(i  ,j  ,k+1))
      NFS(3) = 0.5_R_P*(mesh%Si(i-1,j  ,k)*mesh%NFi(i-1,j  ,k) + mesh%Si(i-1,j  ,k+1)*mesh%NFi(i-1,j  ,k+1))
      NFS(4) = 0.5_R_P*(mesh%Si(i  ,j  ,k)*mesh%NFi(i  ,j  ,k) + mesh%Si(i  ,j  ,k+1)*mesh%NFi(i  ,j  ,k+1))
      NFS(5) = 0.5_R_P*(mesh%Sj(i  ,j-1,k)*mesh%NFj(i  ,j-1,k) + mesh%Sj(i  ,j-1,k+1)*mesh%NFj(i  ,j-1,k+1))
      NFS(6) = 0.5_R_P*(mesh%Sj(i  ,j  ,k)*mesh%NFj(i  ,j  ,k) + mesh%Sj(i  ,j  ,k+1)*mesh%NFj(i  ,j  ,k+1))
    endselect
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine fv_interface_metrics

    !> Subroutine for computing the velocity vector at interfaces of finite volume centered at interface i,j,k.
    !> @return \b vel(1:6) Type_Vector array.
    subroutine fv_interface_velocity(fluid)
    !-------------------------------------------------------------------------------------------------------------------------------
    implicit none
    type(Type_Fluid_Block), intent(IN):: fluid !< Block-level fluidynamic variables.
    type(Type_Vector)::                  mean  !< Mean velocity vector across the interface.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    select case(dir)
    case('i')
      mean = fluid%P(i,j,k)%v + fluid%P(i+1,j,k)%v

      vel(1) = fluid%P(i  ,j,k)%v
      vel(2) = fluid%P(i+1,j,k)%v
      vel(3) = 0.25_R_P*(mean + fluid%P(i,j-1,k  )%v + fluid%P(i+1,j-1,k  )%v)
      vel(4) = 0.25_R_P*(mean + fluid%P(i,j+1,k  )%v + fluid%P(i+1,j+1,k  )%v)
      vel(5) = 0.25_R_P*(mean + fluid%P(i,j  ,k-1)%v + fluid%P(i+1,j  ,k-1)%v)
      vel(6) = 0.25_R_P*(mean + fluid%P(i,j  ,k+1)%v + fluid%P(i+1,j  ,k+1)%v)
    case('j')
      mean = fluid%P(i,j,k)%v + fluid%P(i,j+1,k)%v

      vel(1) = fluid%P(i,j  ,k)%v
      vel(2) = fluid%P(i,j+1,k)%v
      vel(3) = 0.25_R_P*(mean + fluid%P(i  ,j,k-1)%v + fluid%P(i  ,j+1,k-1)%v)
      vel(4) = 0.25_R_P*(mean + fluid%P(i  ,j,k+1)%v + fluid%P(i  ,j+1,k+1)%v)
      vel(5) = 0.25_R_P*(mean + fluid%P(i-1,j,k  )%v + fluid%P(i-1,j+1,k  )%v)
      vel(6) = 0.25_R_P*(mean + fluid%P(i+1,j,k  )%v + fluid%P(i+1,j+1,k  )%v)
    case('k')
      mean = fluid%P(i,j,k)%v + fluid%P(i,j,k+1)%v

      vel(1) = fluid%P(i,j,k  )%v
      vel(2) = fluid%P(i,j,k+1)%v
      vel(3) = 0.25_R_P*(mean + fluid%P(i-1,j  ,k)%v + fluid%P(i-1,j  ,k+1)%v)
      vel(4) = 0.25_R_P*(mean + fluid%P(i+1,j  ,k)%v + fluid%P(i+1,j  ,k+1)%v)
      vel(5) = 0.25_R_P*(mean + fluid%P(i  ,j-1,k)%v + fluid%P(i  ,j-1,k+1)%v)
      vel(6) = 0.25_R_P*(mean + fluid%P(i  ,j+1,k)%v + fluid%P(i  ,j+1,k+1)%v)
    endselect
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine fv_interface_velocity

    !> Function for computing first partial derivative by means of Finite Volumes approach (Green's theorem).
    !> Using the Green's theorem the first partial derivative of \f$u\f$ in \f$\vec i\f$ direction could be written as
    !> \f$\frac{{\partial u}}{{\partial i}} =\frac{1}{V}\sum\limits_{f = 1}^6 {{u_f}\overrightarrow {{n_f}} \cdot \vec i\,{S_f}}\f$
    !> being \f$V\f$ the value of finite volume, \f$\overrightarrow {{n_f}}\f$ the outward unit normal of \f$f^{th}\f$ face which
    !> area is \f$S_f\f$.
    !> @note It is assumed that the finite volume is discretized by means of a hexahedron.
    !> @return \b fpd real(R_P) variable.
    function dudi_FV(u,nsi,v) result(fpd)
    !-------------------------------------------------------------------------------------------------------------------------------
    implicit none
    real(R_P), intent(IN):: u(1:6)   !< Values of variable to be differentiated at each of 6 interfaces surrounding finite volume.
    real(R_P), intent(IN):: nsi(1:6) !< Area of 6 interfaces surrounding finite volume multiplied by normals projected along 'i'.
    real(R_P), intent(IN):: v        !< Value of finite volume.
    real(R_P)::             fpd      !< First partial derivative of 'u' in 'i' direction.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    fpd = (u(2)*nsi(2) - u(1)*nsi(1) + u(4)*nsi(4) - u(3)*nsi(3) + u(6)*nsi(6) - u(5)*nsi(5))/v
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endfunction dudi_FV

    !> Subroutine for computing the shear stress tensor at center of a finite volume.
    subroutine shear_stress()
    !-------------------------------------------------------------------------------------------------------------------------------
    implicit none
    real(R_P)::         vol !< Value of finite volume.
    type(Type_Tensor):: rst !< Rate of strain tensor.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    ! computing the value of the finite volume
    select case(dir)
    case('i')
      vol=0.5_R_P*(block%mesh%V(i,j,k) + block%mesh%V(i+1,j,k))
    case('j')
      vol=0.5_R_P*(block%mesh%V(i,j,k) + block%mesh%V(i,j+1,k))
    case('k')
      vol=0.5_R_P*(block%mesh%V(i,j,k) + block%mesh%V(i,j,k+1))
    endselect
    ! computing the gradient of velocity vector
    rst%x%x = dudi_FV(u=vel%x,nsi=NFS%x,v=vol)
    rst%x%y = dudi_FV(u=vel%x,nsi=NFS%y,v=vol)
    rst%x%z = dudi_FV(u=vel%x,nsi=NFS%z,v=vol)
    rst%y%x = dudi_FV(u=vel%y,nsi=NFS%x,v=vol)
    rst%y%y = dudi_FV(u=vel%y,nsi=NFS%y,v=vol)
    rst%y%z = dudi_FV(u=vel%y,nsi=NFS%z,v=vol)
    rst%z%x = dudi_FV(u=vel%z,nsi=NFS%x,v=vol)
    rst%z%y = dudi_FV(u=vel%z,nsi=NFS%y,v=vol)
    rst%z%z = dudi_FV(u=vel%z,nsi=NFS%z,v=vol)
    ! computing the shear stress tensor
    tau%x%x = global%adim%Re_inv*rst%x%x*4._R_P/3._R_P
    tau%x%y = global%adim%Re_inv*(rst%x%y+rst%y%x)
    tau%x%z = global%adim%Re_inv*(rst%x%z+rst%z%x)
    tau%y%x = tau%x%y
    tau%y%y = global%adim%Re_inv*rst%y%y*4._R_P/3._R_P
    tau%y%z = global%adim%Re_inv*(rst%y%z+rst%z%y)
    tau%z%x = tau%x%z
    tau%z%y = tau%y%z
    tau%z%z = global%adim%Re_inv*rst%z%z*4._R_P/3._R_P
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine shear_stress
endsubroutine fluxes_diffusive
endmodule Lib_Fluxes_Diffusive
