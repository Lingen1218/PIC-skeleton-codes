c Fortran library for Skeleton 3D Electromagnetic OpenMP PIC Code field
c diagnostics
c written by viktor k. decyk, ucla
c copyright 1994, regents of the university of california
c-----------------------------------------------------------------------
      subroutine MPOTP3(q,pot,ffc,we,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,   
     1nzhd)
c this subroutine solves 3d poisson's equation in fourier space for
c for potential with periodic boundary conditions.
c input: q,ffc,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,nzhd, output: pot,we
c approximate flop count is:
c 26*nxc*nyc*nzc + 14*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c potential is calculated using the equation:
c pot(kx,ky,kz) = g(kx,ky,kz)*q(kx,ky,kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers,
c g(kx,ky,kz) = (affp/(kx**2+ky**2+kz**2))*s(kx,ky,kz),
c s(kx,ky,kz) = exp(-((kx*ax)**2+(ky*ay)**2+(kz*az)**2)/2), except for
c pot(kx=pi) = 0, pot(ky=pi) = 0, pot(kz=pi) = 0, and
c pot(kx=0,ky=0,kz=0) = 0
c q(j,k,l) = complex charge density for fourier mode (j-1,k-1,l-1)
c pot(j,k,l) = complex potential for fourier mode (j-1,k-1,l-1)
c real(ffc(j,k,l)) = potential green's function g
c imag(ffc(j,k,l)) = finite-size particle shape factor s
c for fourier mode (j-1,k-1,l-1)
c electric field energy is also calculated, using
c we = nx*ny*nz*sum((affp/(kx**2+ky**2+kz**2))*
c    |q(kx,ky,kz)*s(kx,ky,kz)|**2)
c where affp = normalization constant = nx*ny*nz/np,
c where np=number of particles
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of scalar field arrays, must be >= nx/2
c nyv = second dimension of scalar field arrays, must be >= ny
c nzv = third dimension of scalar field arrays, must be >= nz
c nxhd = first dimension of form factor array, must be >= nx/2
c nyhd = second dimension of form factor array, must be >= ny/2
c nzhd = third dimension of form factor array, must be >= nz/2
      implicit none
      integer  nx, ny, nz, nxvh, nyv, nzv, nxhd, nyhd, nzhd
      real we
      complex q, pot, ffc
      dimension q(nxvh,nyv,nzv), pot(nxvh,nyv,nzv)
      dimension ffc(nxhd,nyhd,nzhd)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real at1, at2
      complex zero
      double precision wp, sum1, sum2
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      zero = cmplx(0.0,0.0)
c calculate potential and sum field energy
      sum1 = 0.0d0
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,at1,at2,wp) REDUCTION(+:sum1)
      do 50 l = 2, nzh
      l1 = nz2 - l
      wp = 0.0d0
      do 20 k = 2, nyh
      k1 = ny2 - k
      do 10 j = 2, nxh
      at2 = real(ffc(j,k,l))
      at1 = at2*aimag(ffc(j,k,l))
      pot(j,k,l) = at2*q(j,k,l)
      pot(j,k1,l) = at2*q(j,k1,l)
      pot(j,k,l1) = at2*q(j,k,l1)
      pot(j,k1,l1) = at2*q(j,k1,l1)
      wp = wp + at1*(q(j,k,l)*conjg(q(j,k,l))                           
     1   + q(j,k1,l)*conjg(q(j,k1,l)) + q(j,k,l1)*conjg(q(j,k,l1))      
     2   + q(j,k1,l1)*conjg(q(j,k1,l1)))
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      at2 = real(ffc(1,k,l))
      at1 = at2*aimag(ffc(1,k,l))
      pot(1,k,l) = at2*q(1,k,l)
      pot(1,k1,l) = zero
      pot(1,k,l1) = at2*q(1,k,l1)
      pot(1,k1,l1) = zero
      wp = wp + at1*(q(1,k,l)*conjg(q(1,k,l))                           
     1   + q(1,k,l1)*conjg(q(1,k,l1)))
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      at2 = real(ffc(j,1,l))
      at1 = at2*aimag(ffc(j,1,l))
      pot(j,1,l) = at2*q(j,1,l)
      pot(j,k1,l) = zero
      pot(j,1,l1) = at2*q(j,1,l1)
      pot(j,k1,l1) = zero
      wp = wp + at1*(q(j,1,l)*conjg(q(j,1,l))                           
     1   + q(j,1,l1)*conjg(q(j,1,l1)))
   40 continue
c mode numbers kx = 0, nx/2
      at2 = real(ffc(1,1,l))
      at1 = at2*aimag(ffc(1,1,l))
      pot(1,1,l) = at2*q(1,1,l)
      pot(1,k1,l) = zero
      pot(1,1,l1) = zero
      pot(1,k1,l1) = zero
      wp = wp + at1*(q(1,1,l)*conjg(q(1,1,l)))
      sum1 = sum1 + wp
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
      sum2 = 0.0d0
!$OMP PARALLEL DO PRIVATE(j,k,k1,at1,at2,wp) REDUCTION(+:sum2)
      do 70 k = 2, nyh
      k1 = ny2 - k
      wp = 0.0d0
      do 60 j = 2, nxh
      at2 = real(ffc(j,k,1))
      at1 = at2*aimag(ffc(j,k,1))
      pot(j,k,1) = at2*q(j,k,1)
      pot(j,k1,1) = at2*q(j,k1,1)
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
      wp = wp + at1*(q(j,k,1)*conjg(q(j,k,1))
     1   + q(j,k1,1)*conjg(q(j,k1,1)))
   60 continue
c mode numbers kx = 0, nx/2
      at2 = real(ffc(1,k,1))
      at1 = at2*aimag(ffc(1,k,1))
      pot(1,k,1) = at2*q(1,k,1)
      pot(1,k1,1) = zero
      pot(1,k,l1) = zero
      pot(1,k1,l1) = zero
      wp = wp + at1*(q(1,k,1)*conjg(q(1,k,1)))
      sum2 = sum2 + wp
   70 continue
!$OMP END PARALLEL DO
      wp = 0.0d0
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      at2 = real(ffc(j,1,1))
      at1 = at2*aimag(ffc(j,1,1))
      pot(j,1,1) = at2*q(j,1,1)
      pot(j,k1,1) = zero
      pot(j,1,l1) = zero
      pot(j,k1,l1) = zero
      wp = wp + at1*(q(j,1,1)*conjg(q(j,1,1)))
   80 continue
      pot(1,1,1) = zero
      pot(1,k1,1) = zero
      pot(1,1,l1) = zero
      pot(1,k1,l1) = zero
      we = real(nx)*real(ny)*real(nz)*(sum1 + sum2 + wp)
      return
      end
c-----------------------------------------------------------------------
      subroutine MDIVF3(f,df,nx,ny,nz,nxvh,nyv,nzv)
c this subroutine calculates the divergence in fourier space
c input: all except df, output: df
c approximate flop count is:
c 35*nxc*nyc*nzc + 16*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c the divergence is calculated using the equation:
c df(kx,ky,kz) = sqrt(-1)*(kx*fx(kx,ky,kz)+ky*fy(kx,ky,kz)
c                       +kz*fz(kx,ky,kz))
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers, except for
c df(kx=pi) = 0, df(ky=pi) = 0, df(kz=pi) = 0
c and df(kx=0,ky=0,kz=0) = 0.
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of scalar field arrays, must be >= nx/2
c nyv = second dimension of scalar field arrays, must be >= ny
c nzv = third dimension of scalar field arrays, must be >= nz
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv
      complex f, df
      dimension f(3,nxvh,nyv,nzv), df(nxvh,nyv,nzv)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real dnx, dny, dnz, dkx, dky, dkz
      complex zero, zt1
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      zero = cmplx(0.0,0.0)
c calculate the divergence
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,dkx,dky,dkz,zt1)
      do 50 l = 2, nzh
      l1 = nz2 - l
      dkz = dnz*real(l - 1)
      do 20 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 10 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = dkx*f(1,j,k,l) + dky*f(2,j,k,l) + dkz*f(3,j,k,l)
      df(j,k,l) = cmplx(-aimag(zt1),real(zt1))
      zt1 = dkx*f(1,j,k1,l) - dky*f(2,j,k1,l) + dkz*f(3,j,k1,l)
      df(j,k1,l) = cmplx(-aimag(zt1),real(zt1))
      zt1 = dkx*f(1,j,k,l1) + dky*f(2,j,k,l1) - dkz*f(3,j,k,l1)
      df(j,k,l1) = cmplx(-aimag(zt1),real(zt1))
      zt1 = dkx*f(1,j,k1,l1) - dky*f(2,j,k1,l1) - dkz*f(3,j,k1,l1)
      df(j,k1,l1) = cmplx(-aimag(zt1),real(zt1))
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      zt1 = dky*f(2,1,k,l) + dkz*f(3,1,k,l)
      df(1,k,l) = cmplx(-aimag(zt1),real(zt1))
      df(1,k1,l) = zero
      zt1 = dky*f(2,1,k,l1) - dkz*f(3,1,k,l1)
      df(1,k,l1) = cmplx(-aimag(zt1),real(zt1))
      df(1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = dkx*f(1,j,1,l) + dkz*f(3,j,1,l)
      df(j,1,l) = cmplx(-aimag(zt1),real(zt1))
      df(j,k1,l) = zero
      zt1 = dkx*f(1,j,1,l1) - dkz*f(3,j,1,l1)
      df(j,1,l1) = cmplx(-aimag(zt1),real(zt1))
      df(j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      df(1,1,l) = dkz*cmplx(-aimag(f(3,1,1,l)),real(f(3,1,1,l)))
      df(1,k1,l) = zero
      df(1,1,l1) = zero
      df(1,k1,l1) = zero
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
!$OMP PARALLEL DO PRIVATE(j,k,k1,dkx,dky,zt1)
      do 70 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 60 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = dkx*f(1,j,k,1) + dky*f(2,j,k,1)
      df(j,k,1) = cmplx(-aimag(zt1),real(zt1))
      zt1 = dkx*f(1,j,k1,1) - dky*f(2,j,k1,1)
      df(j,k1,1) = cmplx(-aimag(zt1),real(zt1))
      df(j,k,l1) = zero
      df(j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      df(1,k,1) = dky*cmplx(-aimag(f(2,1,k,1)),real(f(2,1,k,1)))
      df(1,k1,1) = zero
      df(1,k,l1) = zero
      df(1,k1,l1) = zero
   70 continue
!$OMP END PARALLEL DO
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      dkx = dnx*real(j - 1)
      df(j,1,1) = dkx*cmplx(-aimag(f(1,j,1,1)),real(f(1,j,1,1)))
      df(j,k1,1) = zero
      df(j,1,l1) = zero
      df(j,k1,l1) = zero
   80 continue
      df(1,1,1) = zero
      df(1,k1,1) = zero
      df(1,1,l1) = zero
      df(1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MGRADF3(df,f,nx,ny,nz,nxvh,nyv,nzv)
c this subroutine calculates the gradient in fourier space
c input: all except f, output: f
c approximate flop count is:
c 30*nxc*nyc*nzc + 12*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c the gradient is calculated using the equations:
c fx(kx,ky,kz) = sqrt(-1)*kx*df(kx,ky,kz)
c fy(kx,ky,kz) = sqrt(-1)*ky*df(kx,ky,kz)
c fz(kx,ky,kz) = sqrt(-1)*kz*df(kx,ky,kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers, except for
c fx(kx=pi) = fy(kx=pi) = fz(kx=pi) = 0,
c fx(ky=pi) = fy(ky=pi) = fx(ky=pi) = 0,
c fx(kz=pi) = fy(kz=pi) = fz(kz=pi) = 0,
c fx(kx=0,ky=0,kz=0) = fy(kx=0,ky=0,kz=0) = fz(kx=0,ky=0,kz=0) = 0.
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of scalar field arrays, must be >= nxh
c nyv = second dimension of scalar field arrays, must be >= ny
c nzv = third dimension of scalar field arrays, must be >= nz
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv
      complex df, f
      dimension df(nxvh,nyv,nzv), f(3,nxvh,nyv,nzv)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real dnx, dny, dnz, dkx, dky, dkz
      complex zero, zt1
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      zero = cmplx(0.0,0.0)
c calculate the gradient
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,dkx,dky,dkz,zt1)
      do 50 l = 2, nzh
      l1 = nz2 - l
      dkz = dnz*real(l - 1)
      do 20 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 10 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(df(j,k,l)),real(df(j,k,l)))
      f(1,j,k,l) = dkx*zt1
      f(2,j,k,l) = dky*zt1
      f(3,j,k,l) = dkz*zt1
      zt1 = cmplx(-aimag(df(j,k1,l)),real(df(j,k1,l)))
      f(1,j,k1,l) = dkx*zt1
      f(2,j,k1,l) = -dky*zt1
      f(3,j,k1,l) = dkz*zt1
      zt1 = cmplx(-aimag(df(j,k,l1)),real(df(j,k,l1)))
      f(1,j,k,l1) = dkx*zt1
      f(2,j,k,l1) = dky*zt1
      f(3,j,k,l1) = -dkz*zt1
      zt1 = cmplx(-aimag(df(j,k1,l1)),real(df(j,k1,l1)))
      f(1,j,k1,l1) = dkx*zt1
      f(2,j,k1,l1) = -dky*zt1
      f(3,j,k1,l1) = -dkz*zt1
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      zt1 = cmplx(-aimag(df(1,k,l)),real(df(1,k,l)))
      f(1,1,k,l) = 0.
      f(2,1,k,l) = dky*zt1
      f(3,1,k,l) = dkz*zt1
      f(1,1,k1,l) = zero
      f(2,1,k1,l) = zero
      f(3,1,k1,l) = zero
      zt1 = cmplx(-aimag(df(1,k,l1)),real(df(1,k,l1)))
      f(1,1,k,l1) = 0.
      f(2,1,k,l1) = dky*zt1
      f(3,1,k,l1) = -dkz*zt1
      f(1,1,k1,l1) = zero
      f(2,1,k1,l1) = zero
      f(3,1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(df(j,1,l)),real(df(j,1,l)))
      f(1,j,1,l) = dkx*zt1
      f(2,j,1,l) = zero
      f(3,j,1,l) = dkz*zt1
      f(1,j,k1,l) = zero
      f(2,j,k1,l) = zero
      f(3,j,k1,l) = zero
      zt1 = cmplx(-aimag(df(j,1,l1)),real(df(j,1,l1)))
      f(1,j,1,l1) = dkx*zt1
      f(2,j,1,l1) = zero
      f(3,j,1,l1) = -dkz*zt1
      f(1,j,k1,l1) = zero
      f(2,j,k1,l1) = zero
      f(3,j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      f(1,1,1,l) = zero
      f(2,1,1,l) = zero
      f(3,1,1,l) = dkz*cmplx(-aimag(df(1,1,l)),real(df(1,1,l)))
      f(1,1,k1,l) = zero
      f(2,1,k1,l) = zero
      f(3,1,k1,l) = zero
      f(1,1,1,l1) = zero
      f(2,1,1,l1) = zero
      f(3,1,1,l1) = zero
      f(1,1,k1,l1) = zero
      f(2,1,k1,l1) = zero
      f(3,1,k1,l1) = zero
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
!$OMP PARALLEL DO PRIVATE(j,k,k1,dkx,dky,zt1)
      do 70 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 60 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(df(j,k,1)),real(df(j,k,1)))
      f(1,j,k,1) = dkx*zt1
      f(2,j,k,1) = dky*zt1
      f(3,j,k,1) = zero
      zt1 = cmplx(-aimag(df(j,k1,1)),real(df(j,k1,1)))
      f(1,j,k1,1) = dkx*zt1
      f(2,j,k1,1) = -dky*zt1
      f(3,j,k1,1) = zero
      f(1,j,k,l1) = zero
      f(2,j,k,l1) = zero
      f(3,j,k,l1) = zero
      f(1,j,k1,l1) = zero
      f(2,j,k1,l1) = zero
      f(3,j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      f(1,1,k,1) = zero
      f(2,1,k,1) = dky*cmplx(-aimag(df(1,k,1)),real(df(1,k,1)))
      f(3,1,k,1) = zero
      f(1,1,k1,1) = zero
      f(2,1,k1,1) = zero
      f(3,1,k1,1) = zero
      f(1,1,k,l1) = zero
      f(2,1,k,l1) = zero
      f(3,1,k,l1) = zero
      f(1,1,k1,l1) = zero
      f(2,1,k1,l1) = zero
      f(3,1,k1,l1) = zero
   70 continue
!$OMP END PARALLEL DO
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      dkx = dnx*real(j - 1)
      f(1,j,1,1) = dkx*cmplx(-aimag(df(j,1,1)),real(df(j,1,1)))
      f(2,j,1,1) = zero
      f(3,j,1,1) = zero
      f(1,j,k1,1) = zero
      f(2,j,k1,1) = zero
      f(3,j,k1,1) = zero
      f(1,j,1,l1) = zero
      f(2,j,1,l1) = zero
      f(3,j,1,l1) = zero
      f(1,j,k1,l1) = zero
      f(2,j,k1,l1) = zero
      f(3,j,k1,l1) = zero
   80 continue
      f(1,1,1,1) = zero
      f(2,1,1,1) = zero
      f(3,1,1,1) = zero
      f(1,1,k1,1) = zero
      f(2,1,k1,1) = zero
      f(3,1,k1,1) = zero
      f(1,1,1,l1) = zero
      f(2,1,1,l1) = zero
      f(3,1,1,l1) = zero
      f(1,1,k1,l1) = zero
      f(2,1,k1,l1) = zero
      f(3,1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MCURLF3(f,g,nx,ny,nz,nxvh,nyv,nzv)
c this subroutine calculates the curl in fourier space
c input: all except g, output: g
c approximate flop count is:
c 86*nxc*nyc*nzc + 32*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c the curl is calculated using the equations:
c gx(kx,ky,kz) = sqrt(-1)*(ky*fz(kx,ky,kz)-kz*fy(kx,ky,kz))
c gy(kx,ky,kz) = sqrt(-1)*(kz*fx(kx,ky,kz)-kx*fz(kx,ky,kz))
c gz(kx,ky,kz) = sqrt(-1)*(kx*fy(kx,ky,kz)-ky*fx(kx,ky,kz))
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers, except for
c gx(kx=pi) = gy(kx=pi) = gz(kx=pi) = 0,
c gx(ky=pi) = gy(ky=pi) = gx(ky=pi) = 0,
c gx(kz=pi) = gy(kz=pi) = gz(kz=pi) = 0,
c gx(kx=0,ky=0,kz=0) = gy(kx=0,ky=0,kz=0) = gz(kx=0,ky=0,kz=0) = 0.
c nx/ny/nz = system length in x/y/z direction
c nxvh = second dimension of vector field arrays, must be >= nx/2
c nyv = third dimension of vector field arrays, must be >= ny
c nzv = fourth dimension of vector field arrays, must be >= nz
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv
      complex f, g
      dimension f(3,nxvh,nyv,nzv), g(3,nxvh,nyv,nzv)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real dnx, dny, dnz, dkx, dky, dkz
      complex zero, zt1, zt2, zt3
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      zero = cmplx(0.0,0.0)
c calculate the curl
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,dkx,dky,dkz,zt1,zt2,zt3)
      do 50 l = 2, nzh
      l1 = nz2 - l
      dkz = dnz*real(l - 1)
      do 20 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 10 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(f(3,j,k,l)),real(f(3,j,k,l)))
      zt2 = cmplx(-aimag(f(2,j,k,l)),real(f(2,j,k,l)))
      zt3 = cmplx(-aimag(f(1,j,k,l)),real(f(1,j,k,l)))
      g(1,j,k,l) = dky*zt1 - dkz*zt2
      g(2,j,k,l) = dkz*zt3 - dkx*zt1
      g(3,j,k,l) = dkx*zt2 - dky*zt3
      zt1 = cmplx(-aimag(f(3,j,k1,l)),real(f(3,j,k1,l)))
      zt2 = cmplx(-aimag(f(2,j,k1,l)),real(f(2,j,k1,l)))
      zt3 = cmplx(-aimag(f(1,j,k1,l)),real(f(1,j,k1,l)))
      g(1,j,k1,l) = -dky*zt1 - dkz*zt2
      g(2,j,k1,l) = dkz*zt3 - dkx*zt1
      g(3,j,k1,l) = dkx*zt2 + dky*zt3
      zt1 = cmplx(-aimag(f(3,j,k,l1)),real(f(3,j,k,l1)))
      zt2 = cmplx(-aimag(f(2,j,k,l1)),real(f(2,j,k,l1)))
      zt3 = cmplx(-aimag(f(1,j,k,l1)),real(f(1,j,k,l1)))
      g(1,j,k,l1) = dky*zt1 + dkz*zt2
      g(2,j,k,l1) = -dkz*zt3 - dkx*zt1
      g(3,j,k,l1) = dkx*zt2 - dky*zt3
      zt1 = cmplx(-aimag(f(3,j,k1,l1)),real(f(3,j,k1,l1)))
      zt2 = cmplx(-aimag(f(2,j,k1,l1)),real(f(2,j,k1,l1)))
      zt3 = cmplx(-aimag(f(1,j,k1,l1)),real(f(1,j,k1,l1)))
      g(1,j,k1,l1) = -dky*zt1 + dkz*zt2
      g(2,j,k1,l1) = -dkz*zt3 - dkx*zt1
      g(3,j,k1,l1) = dkx*zt2 + dky*zt3
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      zt1 = cmplx(-aimag(f(3,1,k,l)),real(f(3,1,k,l)))
      zt2 = cmplx(-aimag(f(2,1,k,l)),real(f(2,1,k,l)))
      zt3 = cmplx(-aimag(f(1,1,k,l)),real(f(1,1,k,l)))
      g(1,1,k,l) = dky*zt1 - dkz*zt2
      g(2,1,k,l) = dkz*zt3
      g(3,1,k,l) = -dky*zt3
      g(1,1,k1,l) = zero
      g(2,1,k1,l) = zero
      g(3,1,k1,l) = zero
      zt1 = cmplx(-aimag(f(3,1,k,l1)),real(f(3,1,k,l1)))
      zt2 = cmplx(-aimag(f(2,1,k,l1)),real(f(2,1,k,l1)))
      zt3 = cmplx(-aimag(f(1,1,k,l1)),real(f(1,1,k,l1)))
      g(1,1,k,l1) = dky*zt1 + dkz*zt2
      g(2,1,k,l1) = -dkz*zt3
      g(3,1,k,l1) = -dky*zt3
      g(1,1,k1,l1) = zero
      g(2,1,k1,l1) = zero
      g(3,1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(f(3,j,1,l)),real(f(3,j,1,l)))
      zt2 = cmplx(-aimag(f(2,j,1,l)),real(f(2,j,1,l)))
      zt3 = cmplx(-aimag(f(1,j,1,l)),real(f(1,j,1,l)))
      g(1,j,1,l) = -dkz*zt2
      g(2,j,1,l) = dkz*zt3 - dkx*zt1
      g(3,j,1,l) = dkx*zt2
      g(1,j,k1,l) = zero
      g(2,j,k1,l) = zero
      g(3,j,k1,l) = zero
      zt1 = cmplx(-aimag(f(3,j,1,l1)),real(f(3,j,1,l1)))
      zt2 = cmplx(-aimag(f(2,j,1,l1)),real(f(2,j,1,l1)))
      zt3 = cmplx(-aimag(f(1,j,1,l1)),real(f(1,j,1,l1)))
      g(1,j,1,l1) = dkz*zt2
      g(2,j,1,l1) = -dkz*zt3 - dkx*zt1
      g(3,j,1,l1) = dkx*zt2
      g(1,j,k1,l1) = zero
      g(2,j,k1,l1) = zero
      g(3,j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      zt2 = cmplx(-aimag(f(2,1,1,l)),real(f(2,1,1,l)))
      zt3 = cmplx(-aimag(f(1,1,1,l)),real(f(1,1,1,l)))
      g(1,1,1,l) = -dkz*zt2
      g(2,1,1,l) = dkz*zt3
      g(3,1,1,l) = zero
      g(1,1,k1,l) = zero
      g(2,1,k1,l) = zero
      g(3,1,k1,l) = zero
      g(1,1,1,l1) = zero
      g(2,1,1,l1) = zero
      g(3,1,1,l1) = zero
      g(1,1,k1,l1) = zero
      g(2,1,k1,l1) = zero
      g(3,1,k1,l1) = zero
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
!$OMP PARALLEL DO PRIVATE(j,k,k1,dkx,dky,zt1,zt2,zt3)
      do 70 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      do 60 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(f(3,j,k,1)),real(f(3,j,k,1)))
      zt2 = cmplx(-aimag(f(2,j,k,1)),real(f(2,j,k,1)))
      zt3 = cmplx(-aimag(f(1,j,k,1)),real(f(1,j,k,1)))
      g(1,j,k,1) = dky*zt1
      g(2,j,k,1) = -dkx*zt1
      g(3,j,k,1) = dkx*zt2 - dky*zt3
      zt1 = cmplx(-aimag(f(3,j,k1,1)),real(f(3,j,k1,1)))
      zt2 = cmplx(-aimag(f(2,j,k1,1)),real(f(2,j,k1,1)))
      zt3 = cmplx(-aimag(f(1,j,k1,1)),real(f(1,j,k1,1)))
      g(1,j,k1,1) = -dky*zt1
      g(2,j,k1,1) = -dkx*zt1
      g(3,j,k1,1) = dkx*zt2 + dky*zt3
      g(1,j,k,l1) = zero
      g(2,j,k,l1) = zero
      g(3,j,k,l1) = zero
      g(1,j,k1,l1) = zero
      g(2,j,k1,l1) = zero
      g(3,j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      zt1 = cmplx(-aimag(f(3,1,k,1)),real(f(3,1,k,1)))
      zt3 = cmplx(-aimag(f(1,1,k,1)),real(f(1,1,k,1)))
      g(1,1,k,1) = dky*zt1
      g(2,1,k,1) = zero
      g(3,1,k,1) = -dky*zt3
      g(1,1,k1,1) = zero
      g(2,1,k1,1) = zero
      g(3,1,k1,1) = zero
      g(1,1,k,l1) = zero
      g(2,1,k,l1) = zero
      g(3,1,k,l1) = zero
      g(1,1,k1,l1) = zero
      g(2,1,k1,l1) = zero
      g(3,1,k1,l1) = zero
   70 continue
!$OMP END PARALLEL DO
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      dkx = dnx*real(j - 1)
      zt1 = cmplx(-aimag(f(3,j,1,1)),real(f(3,j,1,1)))
      zt2 = cmplx(-aimag(f(2,j,1,1)),real(f(2,j,1,1)))
      g(1,j,1,1) = zero
      g(2,j,1,1) = -dkx*zt1
      g(3,j,1,1) = dkx*zt2
      g(1,j,k1,1) = zero
      g(2,j,k1,1) = zero
      g(3,j,k1,1) = zero
      g(1,j,1,l1) = zero
      g(2,j,1,l1) = zero
      g(3,j,1,l1) = zero
      g(1,j,k1,l1) = zero
      g(2,j,k1,l1) = zero
      g(3,j,k1,l1) = zero
   80 continue
      g(1,1,1,1) = zero
      g(2,1,1,1) = zero
      g(3,1,1,1) = zero
      g(1,1,k1,1) = zero
      g(2,1,k1,1) = zero
      g(3,1,k1,1) = zero
      g(1,1,1,l1) = zero
      g(2,1,1,l1) = zero
      g(3,1,1,l1) = zero
      g(1,1,k1,l1) = zero
      g(2,1,k1,l1) = zero
      g(3,1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MAVPOT33(bxyz,axyz,nx,ny,nz,nxvh,nyv,nzv)
c this subroutine calculates 3d vector potential from magnetic field
c in fourier space with periodic boundary conditions.
c input: bxyz, nx, ny, nz, nxvh, nyv, nzv, output: axyz
c approximate flop count is:
c 99*nxc*nyc*nzc + 38*(nxc*nyc + nxc*nzc + nyc*nzc)
c and nxc*nyc*nzc divides
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c the vector potential is calculated using the equations:
c ax(kx,ky,kz) = sqrt(-1)*
c                (ky*bz(kx,ky,kz)-kz*by(kx,ky,kz))/(kx*kx+ky*ky+kz*kz)
c ay(kx,ky,kz) = sqrt(-1)*
c                (kz*bx(kx,ky,kz)-kx*bz(kx,ky,kz))/(kx*kx+ky*ky+kz*kz)
c az(kx,ky,kz) = sqrt(-1)*
c                (kx*by(kx,ky,kz)-ky*bx(kx,ky,kz))/(kx*kx+ky*ky+kz*kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers, except for
c ax(kx=pi) = ay(kx=pi) = az(kx=pi) = 0,
c ax(ky=pi) = ay(ky=pi) = ax(ky=pi) = 0,
c ax(kz=pi) = ay(kz=pi) = az(kz=pi) = 0,
c ax(kx=0,ky=0,kz=0) = ay(kx=0,ky=0,kz=0) = az(kx=0,ky=0,kz=0) = 0.
c bxyz(i,j,k,l) = i component of complex magnetic field
c axyz(i,j,k,l) = i component of complex vector potential
c all for fourier mode (j-1,k-1,l-1)
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of field arrays, must be >= nxh
c nyv = second dimension of field arrays, must be >= ny
c nzv = third dimension of field arrays, must be >= nz
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv
      complex bxyz, axyz
      dimension bxyz(3,nxvh,nyv,nzv), axyz(3,nxvh,nyv,nzv)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real dnx, dny, dnz, dkx, dky, dkz, dky2, dkz2, dkyz2
      real at1, at2, at3, at4
      complex zero, zt1, zt2, zt3
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      zero = cmplx(0.0,0.0)
c calculate vector potential
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
      do 50 l = 2, nzh
      l1 = nz2 - l
      dkz = dnz*real(l - 1)
      dkz2 = dkz*dkz
      do 20 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      dkyz2 = dky*dky + dkz2
      do 10 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dkyz2)
      at2 = dkx*at1
      at3 = dky*at1
      at4 = dkz*at1
      zt1 = cmplx(-aimag(bxyz(3,j,k,l)),real(bxyz(3,j,k,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,l)),real(bxyz(2,j,k,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,l)),real(bxyz(1,j,k,l)))
      axyz(1,j,k,l) = at3*zt1 - at4*zt2
      axyz(2,j,k,l) = at4*zt3 - at2*zt1
      axyz(3,j,k,l) = at2*zt2 - at3*zt3
      zt1 = cmplx(-aimag(bxyz(3,j,k1,l)),real(bxyz(3,j,k1,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,l)),real(bxyz(2,j,k1,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,l)),real(bxyz(1,j,k1,l)))
      axyz(1,j,k1,l) = -at3*zt1 - at4*zt2
      axyz(2,j,k1,l) = at4*zt3 - at2*zt1
      axyz(3,j,k1,l) = at2*zt2 + at3*zt3
      zt1 = cmplx(-aimag(bxyz(3,j,k,l1)),real(bxyz(3,j,k,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,l1)),real(bxyz(2,j,k,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,l1)),real(bxyz(1,j,k,l1)))
      axyz(1,j,k,l1) = at3*zt1 + at4*zt2
      axyz(2,j,k,l1) = -at4*zt3 - at2*zt1
      axyz(3,j,k,l1) = at2*zt2 - at3*zt3
      zt1 = cmplx(-aimag(bxyz(3,j,k1,l1)),real(bxyz(3,j,k1,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,l1)),real(bxyz(2,j,k1,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,l1)),real(bxyz(1,j,k1,l1)))
      axyz(1,j,k1,l1) = -at3*zt1 + at4*zt2
      axyz(2,j,k1,l1) = -at4*zt3 - at2*zt1
      axyz(3,j,k1,l1) = at2*zt2 + at3*zt3
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      at1 = 1.0/(dky*dky + dkz2)
      at3 = dky*at1
      at4 = dkz*at1
      zt1 = cmplx(-aimag(bxyz(3,1,k,l)),real(bxyz(3,1,k,l)))
      zt2 = cmplx(-aimag(bxyz(2,1,k,l)),real(bxyz(2,1,k,l)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,l)),real(bxyz(1,1,k,l)))
      axyz(1,1,k,l) = at3*zt1 - at4*zt2
      axyz(2,1,k,l) = at4*zt3
      axyz(3,1,k,l) = -at3*zt3
      axyz(1,1,k1,l) = zero
      axyz(2,1,k1,l) = zero
      axyz(3,1,k1,l) = zero
      zt1 = cmplx(-aimag(bxyz(3,1,k,l1)),real(bxyz(3,1,k,l1)))
      zt2 = cmplx(-aimag(bxyz(2,1,k,l1)),real(bxyz(2,1,k,l1)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,l1)),real(bxyz(1,1,k,l1)))
      axyz(1,1,k,l1) = at3*zt1 + at4*zt2
      axyz(2,1,k,l1) = -at4*zt3
      axyz(3,1,k,l1) = -at3*zt3
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dkz2)
      at2 = dkx*at1
      at4 = dkz*at1
      zt1 = cmplx(-aimag(bxyz(3,j,1,l)),real(bxyz(3,j,1,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,l)),real(bxyz(2,j,1,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,1,l)),real(bxyz(1,j,1,l)))
      axyz(1,j,1,l) = -at4*zt2
      axyz(2,j,1,l) = at4*zt3 - at2*zt1
      axyz(3,j,1,l) = at2*zt2
      axyz(1,j,k1,l) = zero
      axyz(2,j,k1,l) = zero
      axyz(3,j,k1,l) = zero
      zt1 = cmplx(-aimag(bxyz(3,j,1,l1)),real(bxyz(3,j,1,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,l1)),real(bxyz(2,j,1,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,1,l1)),real(bxyz(1,j,1,l1)))
      axyz(1,j,1,l1) = at4*zt2
      axyz(2,j,1,l1) = -at4*zt3 - at2*zt1
      axyz(3,j,1,l1) = at2*zt2
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      at4 = 1.0/dkz
      zt2 = cmplx(-aimag(bxyz(2,1,1,l)),real(bxyz(2,1,1,l)))
      zt3 = cmplx(-aimag(bxyz(1,1,1,l)),real(bxyz(1,1,1,l)))
      axyz(1,1,1,l) = -at4*zt2
      axyz(2,1,1,l) = at4*zt3
      axyz(3,1,1,l) = zero
      axyz(1,1,k1,l) = zero
      axyz(2,1,k1,l) = zero
      axyz(3,1,k1,l) = zero
      axyz(1,1,1,l1) = zero
      axyz(2,1,1,l1) = zero
      axyz(3,1,1,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   50 continue
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
      do 70 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      dky2 = dky*dky
      do 60 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dky2)
      at2 = dkx*at1
      at3 = dky*at1
      zt1 = cmplx(-aimag(bxyz(3,j,k,1)),real(bxyz(3,j,k,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,1)),real(bxyz(2,j,k,1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,1)),real(bxyz(1,j,k,1)))
      axyz(1,j,k,1) = at3*zt1
      axyz(2,j,k,1) = -at2*zt1
      axyz(3,j,k,1) = at2*zt2 - at3*zt3
      zt1 = cmplx(-aimag(bxyz(3,j,k1,1)),real(bxyz(3,j,k1,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,1)),real(bxyz(2,j,k1,1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,1)),real(bxyz(1,j,k1,1)))
      axyz(1,j,k1,1) = -at3*zt1
      axyz(2,j,k1,1) = -at2*zt1
      axyz(3,j,k1,1) = at2*zt2 + at3*zt3
      axyz(1,j,k,l1) = zero
      axyz(2,j,k,l1) = zero
      axyz(3,j,k,l1) = zero
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   60 continue
   70 continue
c mode numbers kx = 0, nx/2
      do 80 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      at3 = 1.0/dky
      zt1 = cmplx(-aimag(bxyz(3,1,k,1)),real(bxyz(3,1,k,1)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,1)),real(bxyz(1,1,k,1)))
      axyz(1,1,k,1) = at3*zt1
      axyz(2,1,k,1) = zero
      axyz(3,1,k,1) = -at3*zt3
      axyz(1,1,k1,1) = zero
      axyz(2,1,k1,1) = zero
      axyz(3,1,k1,1) = zero
      axyz(1,1,k,l1) = zero
      axyz(2,1,k,l1) = zero
      axyz(3,1,k,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   80 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 90 j = 2, nxh
      dkx = dnx*real(j - 1)
      at2 = 1.0/dkx
      zt1 = cmplx(-aimag(bxyz(3,j,1,1)),real(bxyz(3,j,1,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,1)),real(bxyz(2,j,1,1)))
      axyz(1,j,1,1) = zero
      axyz(2,j,1,1) = -at2*zt1
      axyz(3,j,1,1) = at2*zt2
      axyz(1,j,k1,1) = zero
      axyz(2,j,k1,1) = zero
      axyz(3,j,k1,1) = zero
      axyz(1,j,1,l1) = zero
      axyz(2,j,1,l1) = zero
      axyz(3,j,1,l1) = zero
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   90 continue
      axyz(1,1,1,1) = zero
      axyz(2,1,1,1) = zero
      axyz(3,1,1,1) = zero
      axyz(1,1,k1,1) = zero
      axyz(2,1,k1,1) = zero
      axyz(3,1,k1,1) = zero
      axyz(1,1,1,l1) = zero
      axyz(2,1,1,l1) = zero
      axyz(3,1,1,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MAVRPOT33(axyz,bxyz,ffc,ci,nx,ny,nz,nxvh,nyv,nzv,nxhd, 
     1nyhd,nzhd)
c this subroutine solves 3d poisson's equation in fourier space for
c the radiative part of the vector potential
c with periodic boundary conditions.
c input: all, output: axyz
c approximate flop count is:
c 105*nxc*nyc*nzc + 42*(nxc*nyc + nxc*nzc + nyc*nzc)
c and nxc*nyc*nzc divides
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c the vector potential is calculated using the equations:
c ax(kx,ky,kz) = sqrt(-1)*
c (ky*bz(kx,ky,kz)-kz*by(kx,ky,kz) - affp*ci2*cux(kx,ky,kz)*s(kx,ky,kz))
c /(kx*kx+ky*ky+kz*kz)
c ay(kx,ky,kz) = sqrt(-1)*
c (kz*bx(kx,ky,kz)-kx*bz(kx,ky,kz) + affp*ci2*cuy(kx,ky,kz)*s(kx,ky,kz))
c /(kx*kx+ky*ky+kz*kz)
c az(kx,ky,kz) = sqrt(-1)*
c (kx*by(kx,ky,kz)-ky*bx(kx,ky,kz) - affp*ci2*cuz(kx,ky,kz)*s(kx,ky,kz))
c /(kx*kx+ky*ky+kz*kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, ci2 = ci*ci
c and s(kx,ky,kz) = exp(-((kx*ax)**2+(ky*ay)**2+(kz*az)**2)
c j,k,l = fourier mode numbers, except for
c ax(kx=pi) = ay(kx=pi) = az(kx=pi) = 0,
c ax(ky=pi) = ay(ky=pi) = ax(ky=pi) = 0,
c ax(kz=pi) = ay(kz=pi) = az(kz=pi) = 0,
c ax(kx=0,ky=0,kz=0) = ay(kx=0,ky=0,kz=0) = az(kx=0,ky=0,kz=0) = 0.
c axyz(i,j,k,l) = on entry, complex current density cu
c axyz(i,j,k,l) = on exit, complex current radiative vector potential
c bxyz(i,j,k,l) = complex magnetic field
c all for fourier mode (j-1,k-1,l-1)
c ci = reciprical of velocity of light
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of field arrays, must be >= nxh
c nyv = second dimension of field arrays, must be >= ny
c nzv = third dimension of field arrays, must be >= nz
c nxhd = first dimension of form factor array, must be >= nxh
c nyhd = second dimension of form factor array, must be >= nyh
c nzhd = third dimension of form factor array, must be >= nzh
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv, nxhd, nyhd, nzhd
      real ci
      complex axyz, bxyz, ffc
      dimension axyz(3,nxvh,nyv,nzv), bxyz(3,nxvh,nyv,nzv)
      dimension ffc(nxhd,nyhd,nzhd)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real dnx, dny, dnz, afc2, dkx, dky, dkz, dkz2, dky2, dkyz2
      real at1, at2
      complex zero, zt1, zt2, zt3
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      dnx = 6.28318530717959/real(nx)
      dny = 6.28318530717959/real(ny)
      dnz = 6.28318530717959/real(nz)
      afc2 = real(ffc(1,1,1))*ci*ci
      zero = cmplx(0.,0.)
c calculate the radiative vector potential
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
      do 50 l = 2, nzh
      l1 = nz2 - l
      dkz = dnz*real(l - 1)
      dkz2 = dkz*dkz
      do 20 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      dkyz2 = dky*dky + dkz2
      do 10 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dkyz2)
      at2 = afc2*aimag(ffc(j,k,l))
c update radiative vector potential, ky > 0
      zt1 = cmplx(-aimag(bxyz(3,j,k,l)),real(bxyz(3,j,k,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,l)),real(bxyz(2,j,k,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,l)),real(bxyz(1,j,k,l)))
      axyz(1,j,k,l) = at1*(dky*zt1 - dkz*zt2 - at2*axyz(1,j,k,l))
      axyz(2,j,k,l) = at1*(dkz*zt3 - dkx*zt1 - at2*axyz(2,j,k,l))
      axyz(3,j,k,l) = at1*(dkx*zt2 - dky*zt3 - at2*axyz(3,j,k,l))
      zt1 = cmplx(-aimag(bxyz(3,j,k1,l)),real(bxyz(3,j,k1,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,l)),real(bxyz(2,j,k1,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,l)),real(bxyz(1,j,k1,l)))
      axyz(1,j,k1,l) = -at1*(dky*zt1 + dkz*zt2 + at2*axyz(1,j,k1,l))
      axyz(2,j,k1,l) = at1*(dkz*zt3 - dkx*zt1 - at2*axyz(2,j,k1,l))
      axyz(3,j,k1,l) = at1*(dkx*zt2 + dky*zt3 - at2*axyz(3,j,k1,l))
      zt1 = cmplx(-aimag(bxyz(3,j,k,l1)),real(bxyz(3,j,k,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,l1)),real(bxyz(2,j,k,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,l1)),real(bxyz(1,j,k,l1)))
      axyz(1,j,k,l1) = at1*(dky*zt1 + dkz*zt2 - at2*axyz(1,j,k,l1))
      axyz(2,j,k,l1) = -at1*(dkz*zt3 + dkx*zt1 + at2*axyz(2,j,k,l1))
      axyz(3,j,k,l1) = at1*(dkx*zt2 - dky*zt3 - at2*axyz(3,j,k,l1))
      zt1 = cmplx(-aimag(bxyz(3,j,k1,l1)),real(bxyz(3,j,k1,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,l1)),real(bxyz(2,j,k1,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,l1)),real(bxyz(1,j,k1,l1)))
      axyz(1,j,k1,l1) = at1*(dkz*zt2 - dky*zt1 - at2*axyz(1,j,k1,l1))
      axyz(2,j,k1,l1) = -at1*(dkz*zt3 + dkx*zt1 + at2*axyz(2,j,k1,l1))
      axyz(3,j,k1,l1) = at1*(dkx*zt2 + dky*zt3 - at2*axyz(3,j,k1,l1))
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
cdir$ ivdep
      do 30 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      at1 = 1.0/(dky*dky + dkz2)
      at2 = afc2*aimag(ffc(1,k,l))
      zt1 = cmplx(-aimag(bxyz(3,1,k,l)),real(bxyz(3,1,k,l)))
      zt2 = cmplx(-aimag(bxyz(2,1,k,l)),real(bxyz(2,1,k,l)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,l)),real(bxyz(1,1,k,l)))
      axyz(1,1,k,l) = at1*(dky*zt1 - dkz*zt2 - at2*axyz(1,1,k,l))
      axyz(2,1,k,l) = at1*(dkz*zt3 - at2*axyz(2,1,k,l))
      axyz(3,1,k,l) = -at1*(dky*zt3 + at2*axyz(3,1,k,l))
      axyz(1,1,k1,l) = zero
      axyz(2,1,k1,l) = zero
      axyz(3,1,k1,l) = zero
      zt1 = cmplx(-aimag(bxyz(3,1,k,l1)),real(bxyz(3,1,k,l1)))
      zt2 = cmplx(-aimag(bxyz(2,1,k,l1)),real(bxyz(2,1,k,l1)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,l1)),real(bxyz(1,1,k,l1)))
      axyz(1,1,k,l1) = at1*(dky*zt1 + dkz*zt2 - at2*axyz(1,1,k,l1))
      axyz(2,1,k,l1) = -at1*(dkz*zt3 + at2*axyz(2,1,k,l1))
      axyz(3,1,k,l1) = -at1*(dky*zt3 + at2*axyz(3,1,k,l1))
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dkz2)
      at2 = afc2*aimag(ffc(j,1,l))
      zt1 = cmplx(-aimag(bxyz(3,j,1,l)),real(bxyz(3,j,1,l)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,l)),real(bxyz(2,j,1,l)))
      zt3 = cmplx(-aimag(bxyz(1,j,1,l)),real(bxyz(1,j,1,l)))
      axyz(1,j,1,l) = -at1*(dkz*zt2 + at2*axyz(1,j,1,l))
      axyz(2,j,1,l) = at1*(dkz*zt3 - dkx*zt1 - at2*axyz(2,j,1,l))
      axyz(3,j,1,l) = at1*(dkx*zt2 - at2*axyz(3,j,1,l))
      axyz(1,j,k1,l) = zero
      axyz(2,j,k1,l) = zero
      axyz(3,j,k1,l) = zero
      zt1 = cmplx(-aimag(bxyz(3,j,1,l1)),real(bxyz(3,j,1,l1)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,l1)),real(bxyz(2,j,1,l1)))
      zt3 = cmplx(-aimag(bxyz(1,j,1,l1)),real(bxyz(1,j,1,l1)))
      axyz(1,j,1,l1) = at1*(dkz*zt2 - at2*axyz(1,j,1,l1))
      axyz(2,j,1,l1) = -at1*(dkz*zt3 + dkx*zt1 + at2*axyz(2,j,1,l1))
      axyz(3,j,1,l1) = at1*(dkx*zt2 - at2*axyz(3,j,1,l1))
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      at1 = 1.0/dkz2
      at2 = afc2*aimag(ffc(1,1,l))
      zt2 = cmplx(-aimag(bxyz(2,1,1,l)),real(bxyz(2,1,1,l)))
      zt3 = cmplx(-aimag(bxyz(1,1,1,l)),real(bxyz(1,1,1,l)))
      axyz(1,1,1,l) = -at1*(dkz*zt2 + at2*axyz(1,1,1,l))
      axyz(2,1,1,l) = at1*(dkz*zt3 - at2*axyz(2,1,1,l))
      axyz(3,1,1,l) = zero
      axyz(1,1,k1,l) = zero
      axyz(2,1,k1,l) = zero
      axyz(3,1,k1,l) = zero
      axyz(1,1,1,l1) = zero
      axyz(2,1,1,l1) = zero
      axyz(3,1,1,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   50 continue
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
      do 70 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      dky2 = dky*dky
      do 60 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx + dky2)
      at2 = afc2*aimag(ffc(j,k,1))
      zt1 = cmplx(-aimag(bxyz(3,j,k,1)),real(bxyz(3,j,k,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k,1)),real(bxyz(2,j,k,1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k,1)),real(bxyz(1,j,k,1)))
      axyz(1,j,k,1) = at1*(dky*zt1 - at2*axyz(1,j,k,1))
      axyz(2,j,k,1) = -at1*(dkx*zt1 + at2*axyz(2,j,k,1))
      axyz(3,j,k,1) = at1*(dkx*zt2 - dky*zt3 - at2*axyz(3,j,k,1))
      zt1 = cmplx(-aimag(bxyz(3,j,k1,1)),real(bxyz(3,j,k1,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,k1,1)),real(bxyz(2,j,k1,1)))
      zt3 = cmplx(-aimag(bxyz(1,j,k1,1)),real(bxyz(1,j,k1,1)))
      axyz(1,j,k1,1) = -at1*(dky*zt1 + at2*axyz(1,j,k1,1))
      axyz(2,j,k1,1) = -at1*(dkx*zt1 + at2*axyz(2,j,k1,1))
      axyz(3,j,k1,1) = at1*(dkx*zt2 + dky*zt3 - at2*axyz(3,j,k1,1))
      axyz(1,j,k,l1) = zero
      axyz(2,j,k,l1) = zero
      axyz(3,j,k,l1) = zero
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   60 continue
   70 continue
c mode numbers kx = 0, nx/2
      do 80 k = 2, nyh
      k1 = ny2 - k
      dky = dny*real(k - 1)
      at1 = 1.0/(dky*dky)
      at2 = afc2*aimag(ffc(1,k,1))
      zt1 = cmplx(-aimag(bxyz(3,1,k,1)),real(bxyz(3,1,k,1)))
      zt3 = cmplx(-aimag(bxyz(1,1,k,1)),real(bxyz(1,1,k,1)))
      axyz(1,1,k,1) = at1*(dky*zt1 - at2*axyz(1,1,k,1))
      axyz(2,1,k,1) = zero
      axyz(3,1,k,1) = -at1*(dky*zt3 + at2*axyz(3,1,k,1))
      axyz(1,1,k1,1) = zero
      axyz(2,1,k1,1) = zero
      axyz(3,1,k1,1) = zero
      axyz(1,1,k,l1) = zero
      axyz(2,1,k,l1) = zero
      axyz(3,1,k,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
   80 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 90 j = 2, nxh
      dkx = dnx*real(j - 1)
      at1 = 1.0/(dkx*dkx)
      at2 = afc2*aimag(ffc(j,1,1))
      zt1 = cmplx(-aimag(bxyz(3,j,1,1)),real(bxyz(3,j,1,1)))
      zt2 = cmplx(-aimag(bxyz(2,j,1,1)),real(bxyz(2,j,1,1)))
      axyz(1,j,1,1) = zero
      axyz(2,j,1,1) = -at1*(dkx*zt1 + at2*axyz(2,j,1,1))
      axyz(3,j,1,1) = at1*(dkx*zt2 - at2*axyz(3,j,1,1))
      axyz(1,j,k1,1) = zero
      axyz(2,j,k1,1) = zero
      axyz(3,j,k1,1) = zero
      axyz(1,j,1,l1) = zero
      axyz(2,j,1,l1) = zero
      axyz(3,j,1,l1) = zero
      axyz(1,j,k1,l1) = zero
      axyz(2,j,k1,l1) = zero
      axyz(3,j,k1,l1) = zero
   90 continue
      axyz(1,1,1,1) = zero
      axyz(2,1,1,1) = zero
      axyz(3,1,1,1) = zero
      axyz(1,1,k1,1) = zero
      axyz(2,1,k1,1) = zero
      axyz(3,1,k1,1) = zero
      axyz(1,1,1,l1) = zero
      axyz(2,1,1,l1) = zero
      axyz(3,1,1,l1) = zero
      axyz(1,1,k1,l1) = zero
      axyz(2,1,k1,l1) = zero
      axyz(3,1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MSMOOTH3(q,qs,ffc,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,nzhd)
c this subroutine provides a 3d scalar smoothing function
c in fourier space, with periodic boundary conditions.
c input: q,ffc,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,nzhd, output: qs
c approximate flop count is:
c 8*nxc*nyc*nzc + 4*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c smoothing is calculated using the equation:
c qs(kx,ky,kz) = q(kx,ky,kz)*s(kx,ky,kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers,
c g(kx,ky,kz) = (affp/(kx**2+ky**2+kz**2))*s(kx,ky,kz),
c where affp = normalization constant = nx*ny*nz/np,
c and np=number of particles
c s(kx,ky,kz) = exp(-((kx*ax)**2+(ky*ay)**2+(kz*az)**2)/2), except for
c qs(kx=pi) = qs(ky=pi) = qs(kz=pi) = 0, and qs(kx=0,ky=0,kz=0) = 0.
c q(j,k,l) = complex charge density
c qs(j,k,l) = complex smoothed charge density
c for fourier mode (j-1,k-1,l-1)
c real(ffc(j,k,l)) = potential green's function g
c aimag(ffc(j,k,l)) = finite-size particle shape factor s
c for fourier mode (j-1,k-1,l-1)
c nx/ny/nz = system length in x/y/z direction
c nxvh = first dimension of scalar field arrays, must be >= nx/2
c nyv = second dimension of field arrays, must be >= ny
c nzv = third dimension of field arrays, must be >= nz
c nxhd = first dimension of form factor array, must be >= nx/2
c nyhd = second dimension of form factor array, must be >= ny/2
c nzhd = third dimension of form factor array, must be >= nz/2
      implicit none
      integer  nx, ny, nz, nxvh, nyv, nzv, nxhd, nyhd, nzhd
      complex q, qs, ffc
      dimension q(nxvh,nyv,nzv), qs(nxvh,nyv,nzv)
      dimension ffc(nxhd,nyhd,nzhd)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real at1
      complex zero
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      zero = cmplx(0.0,0.0)
c calculate smoothing
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,at1)
      do 50 l = 2, nzh
      l1 = nz2 - l
      do 20 k = 2, nyh
      k1 = ny2 - k
      do 10 j = 2, nxh
      at1 = aimag(ffc(j,k,l))
      qs(j,k,l) = at1*q(j,k,l)
      qs(j,k1,l) = at1*q(j,k1,l)
      qs(j,k,l1) = at1*q(j,k,l1)
      qs(j,k1,l1) = at1*q(j,k1,l1)
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      at1 = aimag(ffc(1,k,l))
      qs(1,k,l) = at1*q(1,k,l)
      qs(1,k1,l) = zero
      qs(1,k,l1) = at1*q(1,k,l1)
      qs(1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      at1 = aimag(ffc(j,1,l))
      qs(j,1,l) = at1*q(j,1,l)
      qs(j,k1,l) = zero
      qs(j,1,l1) = at1*q(j,1,l1)
      qs(j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      at1 = aimag(ffc(1,1,l))
      qs(1,1,l) = at1*q(1,1,l)
      qs(1,k1,l) = zero
      qs(1,1,l1) = zero
      qs(1,k1,l1) = zero
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
!$OMP PARALLEL DO PRIVATE(j,k,k1,at1)
      do 70 k = 2, nyh
      k1 = ny2 - k
      do 60 j = 2, nxh
      at1 = aimag(ffc(j,k,1))
      qs(j,k,1) = at1*q(j,k,1)
      qs(j,k1,1) = at1*q(j,k1,1)
      qs(j,k,l1) = zero
      qs(j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      at1 = aimag(ffc(1,k,1))
      qs(1,k,1) = at1*q(1,k,1)
      qs(1,k1,1) = zero
      qs(1,k,l1) = zero
      qs(1,k1,l1) = zero
   70 continue
!$OMP END PARALLEL DO
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      at1 = aimag(ffc(j,1,1))
      qs(j,1,1) = at1*q(j,1,1)
      qs(j,k1,1) = zero
      qs(j,1,l1) = zero
      qs(j,k1,l1) = zero
   80 continue
      qs(1,1,1) = cmplx(aimag(ffc(1,1,1))*real(q(1,1,1)),0.0)
      qs(1,k1,1) = zero
      qs(1,1,l1) = zero
      qs(1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine MSMOOTH33(cu,cus,ffc,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,  
     1nzhd)
c this subroutine provides a 3d vector smoothing function
c in fourier space, with periodic boundary conditions.
c input: cu,ffc,nx,ny,nz,nxvh,nyv,nzv,nxhd,nyhd,nzhd, output: cus
c approximate flop count is:
c 24*nxc*nyc*nzc + 12*(nxc*nyc + nxc*nzc + nyc*nzc)
c where nxc = nx/2 - 1, nyc = ny/2 - 1, nzc = nz/2 - 1
c smoothing is calculated using the equation:
c cusx(kx,ky,kz) = cux(kx,ky,kz)*s(kx,ky,kz)
c cusy(kx,ky,kz) = cuy(kx,ky,kz)*s(kx,ky,kz)
c cusz(kx,ky,kz) = cuz(kx,ky,kz)*s(kx,ky,kz)
c where kx = 2pi*j/nx, ky = 2pi*k/ny, kz = 2pi*l/nz, and
c j,k,l = fourier mode numbers,
c g(kx,ky,kz) = (affp/(kx**2+ky**2+kz**2))*s(kx,ky,kz),
c where affp = normalization constant = nx*ny*nz/np,
c and np=number of particles
c s(kx,ky,kz) = exp(-((kx*ax)**2+(ky*ay)**2+(kz*az)**2)/2), except for
c cusx(kx=pi) = cusy(kx=pi) = cusz(kx=pi) = 0,
c cusx(ky=pi) = cusy(ky=pi) = cusz(ky=pi) = 0,
c cusx(kz=pi) = cusy(kz=pi) = cusz(kz=pi) = 0,
c cusx(kx=0,ky=0,kz=0) = cusy(kx=0,ky=0,kz=0) = cusz(kx=0,ky=0,kz=0) = 0
c cu(i,j,k,l) = ith-component of complex current density
c cus(i,j,k,l) = ith-component of complex smoothed current density
c for fourier mode (j-1,k-1,l-1)
c aimag(ffc(j,k,l)) = finite-size particle shape factor s
c real(ffc(j,k,l)) = potential green's function g
c for fourier mode (j-1,k-1,l-1)
c nx/ny/nz = system length in x/y/z direction
c nxvh = second dimension of vector field arrays, must be >= nx/2
c nyv = third dimension of vector field arrays, must be >= ny
c nzv = fourth dimension of vector field arrays, must be >= nz
c nxhd = first dimension of form factor array, must be >= nx/2
c nyhd = second dimension of form factor array, must be >= ny/2
c nzhd = third dimension of form factor array, must be >= nz/2
      implicit none
      integer nx, ny, nz, nxvh, nyv, nzv, nxhd, nyhd, nzhd
      complex cu, cus, ffc
      dimension cu(3,nxvh,nyv,nzv), cus(3,nxvh,nyv,nzv)
      dimension ffc(nxhd,nyhd,nzhd)
c local data
      integer nxh, nyh, nzh, ny2, nz2, j, k, l, k1, l1
      real at1
      complex zero
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      ny2 = ny + 2
      nz2 = nz + 2
      zero = cmplx(0.0,0.0)
c calculate smoothing
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL
!$OMP DO PRIVATE(j,k,l,k1,l1,at1)
      do 50 l = 2, nzh
      l1 = nz2 - l
      do 20 k = 2, nyh
      k1 = ny2 - k
      do 10 j = 2, nxh
      at1 = aimag(ffc(j,k,l))
      cus(1,j,k,l) = at1*cu(1,j,k,l)
      cus(2,j,k,l) = at1*cu(2,j,k,l)
      cus(3,j,k,l) = at1*cu(3,j,k,l)
      cus(1,j,k1,l) = at1*cu(1,j,k1,l)
      cus(2,j,k1,l) = at1*cu(2,j,k1,l)
      cus(3,j,k1,l) = at1*cu(3,j,k1,l)
      cus(1,j,k,l1) = at1*cu(1,j,k,l1)
      cus(2,j,k,l1) = at1*cu(2,j,k,l1)
      cus(3,j,k,l1) = at1*cu(3,j,k,l1)
      cus(1,j,k1,l1) = at1*cu(1,j,k1,l1)
      cus(2,j,k1,l1) = at1*cu(2,j,k1,l1)
      cus(3,j,k1,l1) = at1*cu(3,j,k1,l1)
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 k = 2, nyh
      k1 = ny2 - k
      at1 = aimag(ffc(1,k,l))
      cus(1,1,k,l) = at1*cu(1,1,k,l)
      cus(2,1,k,l) = at1*cu(2,1,k,l)
      cus(3,1,k,l) = at1*cu(3,1,k,l)
      cus(1,1,k1,l) = zero
      cus(2,1,k1,l) = zero
      cus(3,1,k1,l) = zero
      cus(1,1,k,l1) = at1*cu(1,1,k,l1)
      cus(2,1,k,l1) = at1*cu(2,1,k,l1)
      cus(3,1,k,l1) = at1*cu(3,1,k,l1)
      cus(1,1,k1,l1) = zero
      cus(2,1,k1,l1) = zero
      cus(3,1,k1,l1) = zero
   30 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 40 j = 2, nxh
      at1 = aimag(ffc(j,1,l))
      cus(1,j,1,l) = at1*cu(1,j,1,l)
      cus(2,j,1,l) = at1*cu(2,j,1,l)
      cus(3,j,1,l) = at1*cu(3,j,1,l)
      cus(1,j,k1,l) = zero
      cus(2,j,k1,l) = zero
      cus(3,j,k1,l) = zero
      cus(1,j,1,l1) = at1*cu(1,j,1,l1)
      cus(2,j,1,l1) = at1*cu(2,j,1,l1)
      cus(3,j,1,l1) = at1*cu(3,j,1,l1)
      cus(1,j,k1,l1) = zero
      cus(2,j,k1,l1) = zero
      cus(3,j,k1,l1) = zero
   40 continue
c mode numbers kx = 0, nx/2
      at1 = aimag(ffc(1,1,l))
      cus(1,1,1,l) = at1*cu(1,1,1,l)
      cus(2,1,1,l) = at1*cu(2,1,1,l)
      cus(3,1,1,l) = at1*cu(3,1,1,l)
      cus(1,1,k1,l) = zero
      cus(2,1,k1,l) = zero
      cus(3,1,k1,l) = zero
      cus(1,1,1,l1) = zero
      cus(2,1,1,l1) = zero
      cus(3,1,1,l1) = zero
      cus(1,1,k1,l1) = zero
      cus(2,1,k1,l1) = zero
      cus(3,1,k1,l1) = zero
   50 continue
!$OMP END DO NOWAIT
!$OMP END PARALLEL
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
!$OMP PARALLEL DO PRIVATE(j,k,k1,at1)
      do 70 k = 2, nyh
      k1 = ny2 - k
      do 60 j = 2, nxh
      at1 = aimag(ffc(j,k,1))
      cus(1,j,k,1) = at1*cu(1,j,k,1)
      cus(2,j,k,1) = at1*cu(2,j,k,1)
      cus(3,j,k,1) = at1*cu(3,j,k,1)
      cus(1,j,k1,1) = at1*cu(1,j,k1,1)
      cus(2,j,k1,1) = at1*cu(2,j,k1,1)
      cus(3,j,k1,1) = at1*cu(3,j,k1,1)
      cus(1,j,k,l1) = zero
      cus(2,j,k,l1) = zero
      cus(3,j,k,l1) = zero
      cus(1,j,k1,l1) = zero
      cus(2,j,k1,l1) = zero
      cus(3,j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      at1 = aimag(ffc(1,k,1))
      cus(1,1,k,1) = at1*cu(1,1,k,1)
      cus(2,1,k,1) = at1*cu(2,1,k,1)
      cus(3,1,k,1) = at1*cu(3,1,k,1)
      cus(1,1,k1,1) = zero
      cus(2,1,k1,1) = zero
      cus(3,1,k1,1) = zero
      cus(1,1,k,l1) = zero
      cus(2,1,k,l1) = zero
      cus(3,1,k,l1) = zero
      cus(1,1,k1,l1) = zero
      cus(2,1,k1,l1) = zero
      cus(3,1,k1,l1) = zero
   70 continue
!$OMP END PARALLEL DO
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 80 j = 2, nxh
      at1 = aimag(ffc(j,1,1))
      cus(1,j,1,1) = at1*cu(1,j,1,1)
      cus(2,j,1,1) = at1*cu(2,j,1,1)
      cus(3,j,1,1) = at1*cu(3,j,1,1)
      cus(1,j,k1,1) = zero
      cus(2,j,k1,1) = zero
      cus(3,j,k1,1) = zero
      cus(1,j,1,l1) = zero
      cus(2,j,1,l1) = zero
      cus(3,j,1,l1) = zero
      cus(1,j,k1,l1) = zero
      cus(2,j,k1,l1) = zero
      cus(3,j,k1,l1) = zero
   80 continue
      at1 = aimag(ffc(1,1,1))
      cus(1,1,1,1) = cmplx(at1*real(cu(1,1,1,1)),0.)
      cus(2,1,1,1) = cmplx(at1*real(cu(2,1,1,1)),0.)
      cus(3,1,1,1) = cmplx(at1*real(cu(3,1,1,1)),0.)
      cus(1,1,k1,1) = zero
      cus(2,1,k1,1) = zero
      cus(3,1,k1,1) = zero
      cus(1,1,1,l1) = zero
      cus(2,1,1,l1) = zero
      cus(3,1,1,l1) = zero
      cus(1,1,k1,l1) = zero
      cus(2,1,k1,l1) = zero
      cus(3,1,k1,l1) = zero
      return
      end
c-----------------------------------------------------------------------
      subroutine RDMODES3(pot,pott,nx,ny,nz,modesx,modesy,modesz,nxvh,  
     1nyv,nzv,modesxd,modesyd,modeszd)
c this subroutine extracts lowest order modes from packed complex array
c pot and stores them into a location in an unpacked complex array pott
c modes stored: kx=(0,1,...,NX/2), ky=(0,+-1,+-2,...,+-(NY/2-1),NY/2),
c kz=(0,+-1,+-2,...,+-(NZ/2-1),NZ/2)
c nx/ny/nz = system length in x/y/z direction
c modesx/modesy/modesz = number of modes to store in x/y/z direction,
c where modesx <= nx/2+1, modesy <= ny/2+1, modesz <= nz/2+1
c nxvh = first dimension of input array pot, nxvh >= nx/2
c nyv = second dimension of input array pot, nyv >= ny
c nzv = third dimension of input array pot, nzv >= nz
c modesxd = first dimension of output array pott, modesxd >= modesx
c modesyd = second dimension of output array pott,
c where modesyd  >= min(2*modesy-1,ny)
c modeszd = third dimension of output array pott,
c where modeszd  >= min(2*modesz-1,nz)
      implicit none
      integer nx, ny, nz, modesx, modesy, modesz, nxvh, nyv, nzv
      integer modesxd, modesyd, modeszd
      complex pot, pott
      dimension pot(nxvh,nyv,nzv), pott(modesxd,modesyd,modeszd)
c local data
      integer nxh, nyh, nzh, lmax, kmax, jmax, ny2, nz2, j, k, l
      integer j1, k1, l1
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      if ((modesx.le.0).or.(modesx.gt.(nxh+1))) return
      if ((modesy.le.0).or.(modesy.gt.(nyh+1))) return
      if ((modesz.le.0).or.(modesz.gt.(nzh+1))) return
      ny2 = ny + 2
      nz2 = nz + 2
      jmax = min0(modesx,nxh)
      kmax = min0(modesy,nyh)
      lmax = min0(modesz,nzh)
      j1 = nxh + 1
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL DO PRIVATE(j,k,l,k1,l1)
      do 50 l = 2, lmax
      l1 = nz2 - l
      do 20 k = 2, kmax
      k1 = ny2 - k
      do 10 j = 2, jmax
      pott(j,2*k-2,2*l-2) = pot(j,k,l)
      pott(j,2*k-1,2*l-2) = pot(j,k1,l)
      pott(j,2*k-2,2*l-1) = pot(j,k,l1)
      pott(j,2*k-1,2*l-1) = pot(j,k1,l1)
   10 continue
c mode numbers kx = 0, nx/2
      pott(1,2*k-2,2*l-2) = pot(1,k,l)
      pott(1,2*k-1,2*l-2) = conjg(pot(1,k,l1))
      pott(1,2*k-2,2*l-1) = pot(1,k,l1)
      pott(1,2*k-1,2*l-1) = conjg(pot(1,k,l))
      if (modesx.gt.nxh) then
         pott(j1,2*k-2,2*l-2) = conjg(pot(1,k1,l1))
         pott(j1,2*k-1,2*l-2) = pot(1,k1,l)
         pott(j1,2*k-2,2*l-1) = conjg(pot(1,k1,l))
         pott(j1,2*k-1,2*l-1) = pot(1,k1,l1)
      endif
   20 continue
c mode numbers ky = 0
      do 30 j = 2, jmax
      pott(j,1,2*l-2) = pot(j,1,l)
      pott(j,1,2*l-1) = pot(j,1,l1)
   30 continue
c mode numbers kx = 0, nx/2
      pott(1,1,2*l-2) = pot(1,1,l)
      pott(1,1,2*l-1) = conjg(pot(1,1,l))
      if (modesx.gt.nxh) then
         pott(j1,1,2*l-2) = conjg(pot(1,1,l1))
         pott(j1,1,2*l-1) = pot(1,1,l1)
      endif
c mode numbers ky = ny/2
      if (modesy.gt.nyh) then
         k1 = nyh + 1
         do 40 j = 2, jmax
         pott(j,ny,2*l-2) = pot(j,k1,l)
         pott(j,ny,2*l-1) = pot(j,k1,l1)
   40    continue
         pott(1,ny,2*l-2) = pot(1,k1,l)
         pott(1,ny,2*l-1) = conjg(pot(1,k1,l))
         if (modesx.gt.nxh) then
            pott(j1,ny,2*l-2) = conjg(pot(1,k1,l1))
            pott(j1,ny,2*l-1) = pot(1,k1,l1)
         endif
      endif
   50 continue
!$OMP END PARALLEL DO
c mode numbers kz = 0
      do 70 k = 2, kmax
      k1 = ny2 - k
      do 60 j = 2, jmax
      pott(j,2*k-2,1) = pot(j,k,1)
      pott(j,2*k-1,1) = pot(j,k1,1)
   60 continue
c mode numbers kx = 0, nx/2
      pott(1,2*k-2,1) = pot(1,k,1)
      pott(1,2*k-1,1) = conjg(pot(1,k,1))
      if (modesx.gt.nxh) then
         pott(j1,2*k-2,1) = conjg(pot(1,k1,1))
         pott(j1,2*k-1,1) = pot(1,k1,1)
      endif
   70 continue
c mode numbers ky = 0
      do 80 j = 2, jmax
      pott(j,1,1) = pot(j,1,1)
   80 continue
      pott(1,1,1) = cmplx(real(pot(1,1,1)),0.0)
      if (modesx.gt.nxh) then
         pott(j1,1,1) = cmplx(aimag(pot(1,1,1)),0.0)
      endif
      if (modesy.gt.nyh) then
         k1 = nyh + 1
c mode numbers ky = ny/2
         do 90 j = 2, jmax
         pott(j,ny,1) = pot(j,k1,1)
   90    continue
         pott(1,ny,1) = cmplx(real(pot(1,k1,1)),0.0)
         if (modesx.gt.nxh) then
            pott(j1,ny,1) = cmplx(aimag(pot(1,k1,1)),0.0)
         endif
      endif
c mode numbers kz = nz/2
      if (modesz.gt.nzh) then
         l1 = nzh + 1
         do 110 k = 2, kmax
         k1 = ny2 - k
         do 100 j = 2, jmax
         pott(j,2*k-2,nz) = pot(j,k,l1)
         pott(j,2*k-1,nz) = pot(j,k1,l1)
  100    continue
c mode numbers kx = 0, nx/2
         pott(1,2*k-2,nz) = pot(1,k,l1)
         pott(1,2*k-1,nz) = conjg(pot(1,k,l1))
         if (modesx.gt.nxh) then
            pott(j1,2*k-2,nz) = conjg(pot(1,k1,l1))
            pott(j1,2*k-1,nz) = pot(1,k1,l1)
         endif
  110    continue
c mode numbers ky = 0
         do 120 j = 2, jmax
         pott(j,1,nz) = pot(j,1,l1)
  120    continue
         pott(1,1,nz) = cmplx(real(pot(1,1,l1)),0.0)
         if (modesx.gt.nxh) then
            pott(j1,1,nz) = cmplx(aimag(pot(1,1,l1)),0.0)
         endif
         if (modesy.gt.nyh) then
            k1 = nyh + 1
c mode numbers ky = ny/2
            do 130 j = 2, jmax
            pott(j,ny,nz) = pot(j,k1,l1)
  130       continue
            pott(1,ny,nz) = cmplx(real(pot(1,k1,l1)),0.0)
            if (modesx.gt.nxh) then
               pott(j1,ny,nz) = cmplx(aimag(pot(1,k1,l1)),0.0)
            endif
         endif
      endif
      return
      end
c-----------------------------------------------------------------------
      subroutine WRMODES3(pot,pott,nx,ny,nz,modesx,modesy,modesz,nxvh,  
     1nyv,nzv,modesxd,modesyd,modeszd)
c this subroutine extracts lowest order modes from a location in an
c unpacked complex array pott and stores them into a packed complex
c array pot
c modes stored: kx=(0,1,...,NX/2), ky=(0,+-1,+-2,...,+-(NY/2-1),NY/2),
c kz=(0,+-1,+-2,...,+-(NZ/2-1),NZ/2)
c nx/ny/nz = system length in x/y/z direction
c modesx/modesy/modesz = number of modes to store in x/y/z direction,
c where modesx <= nx/2+1, modesy <= ny/2+1, modesz <= nz/2+1
c nxvh = first dimension of output array pot, nxvh >= nx/2
c nyv = second dimension of output array pot, nyv >= ny
c nzv = third dimension of output array pot, nzv >= nz
c modesxd = first dimension of input array pott, modesxd >= modesx
c modesyd = second dimension of output array pott,
c where modesyd  >= min(2*modesy-1,ny)
c modeszd = third dimension of output array pott,
c where modeszd  >= min(2*modesz-1,nz)
      implicit none
      integer nx, ny, nz, modesx, modesy, modesz, nxvh, nyv, nzv
      integer modesxd, modesyd, modeszd
      complex pot, pott
      dimension pot(nxvh,nyv,nzv), pott(modesxd,modesyd,modeszd)
c local data
      integer nxh, nyh, nzh, lmax, kmax, jmax, ny2, nz2, j, k, l
      integer j1, k1, l1
      complex zero
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      if ((modesx.le.0).or.(modesx.gt.(nxh+1))) return
      if ((modesy.le.0).or.(modesy.gt.(nyh+1))) return
      if ((modesz.le.0).or.(modesz.gt.(nzh+1))) return
      ny2 = ny + 2
      nz2 = nz + 2
      jmax = min0(modesx,nxh)
      kmax = min0(modesy,nyh)
      lmax = min0(modesz,nzh)
      j1 = nxh + 1
      zero = cmplx(0.0,0.0)
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL DO PRIVATE(j,k,l,k1,l1)
      do 90 l = 2, lmax
      l1 = nz2 - l
      do 30 k = 2, kmax
      k1 = ny2 - k
      do 10 j = 2, jmax
      pot(j,k,l) = pott(j,2*k-2,2*l-2)
      pot(j,k1,l) = pott(j,2*k-1,2*l-2)
      pot(j,k,l1) = pott(j,2*k-2,2*l-1)
      pot(j,k1,l1) = pott(j,2*k-1,2*l-1)
   10 continue
      do 20 j = jmax+1, nxh
      pot(j,k,l) = zero
      pot(j,k1,l) = zero
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
   20 continue
c mode numbers kx = 0, nx/2
      pot(1,k,l) = pott(1,2*k-2,2*l-2)
      pot(1,k1,l) = zero
      pot(1,k,l1) = pott(1,2*k-2,2*l-1)
      pot(1,k1,l1) = zero
      if (modesx.gt.nxh) then
         pot(1,k1,l) = conjg(pott(j1,2*k-2,2*l-1))
         pot(1,k1,l1) = conjg(pott(j1,2*k-2,2*l-2))
      endif
   30 continue
      do 50 k = kmax+1, nyh
      k1 = ny2 - k
      do 40 j = 1, nxh
      pot(j,k,l) = zero
      pot(j,k1,l) = zero
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
   40 continue
   50 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 60 j = 2, jmax
      pot(j,1,l) = pott(j,1,2*l-2)
      pot(j,k1,l) = zero
      pot(j,1,l1) = pott(j,1,2*l-1)
      pot(j,k1,l1) = zero
   60 continue
c mode numbers kx = 0, nx/2
      pot(1,1,l) = pott(1,1,2*l-2)
      pot(1,k1,l) = zero
      pot(1,1,l1) = zero
      pot(1,k1,l1) = zero
      do 70 j = jmax+1, nxh
      pot(j,1,l) = zero
      pot(j,k1,l) = zero
      pot(j,1,l1) = zero
      pot(j,k1,l1) = zero
   70 continue
      if (modesx.gt.nxh) then
         pot(1,1,l1) = conjg(pott(j1,1,2*l-2))
      endif
c mode numbers ky = ny/2
      if (modesy.gt.nyh) then
         do 80 j = 2, jmax
         pot(j,k1,l) = pott(j,ny,2*l-2)
         pot(j,k1,l1) = pott(j,ny,2*l-1)
   80    continue
         pot(1,k1,l) = pott(1,ny,2*l-2)
         if (modesx.gt.nxh) then
            pot(1,k1,l1) = conjg(pott(j1,ny,2*l-2))
         endif
      endif
   90 continue
!$OMP END PARALLEL DO
      do 130 l = modesz+1, nzh
      l1 = nz2 - l
      do 110 k = 2, nyh
      k1 = ny2 - k
      do 100 j = 1, nxh
      pot(j,k,l) = zero
      pot(j,k1,l) = zero
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
  100 continue
  110 continue
      k1 = nyh + 1
      do 120 j = 1, nxh
      pot(j,1,l) = zero
      pot(j,k1,l) = zero
      pot(j,1,l1) = zero
      pot(j,k1,l1) = zero
  120 continue
  130 continue
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
      do 160 k = 2, kmax
      k1 = ny2 - k
      do 140 j = 2, jmax
      pot(j,k,1) = pott(j,2*k-2,1)
      pot(j,k1,1) = pott(j,2*k-1,1)
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
  140 continue
      do 150 j = jmax+1, nxh
      pot(j,k,1) = zero
      pot(j,k1,1) = zero
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
  150 continue
c mode numbers kx = 0, nx/2
      pot(1,k,1) = pott(1,2*k-2,1)
      pot(1,k1,1) = zero
      pot(1,k,l1) = zero
      pot(1,k1,l1) = zero
      if (modesx.gt.nxh) then
         pot(1,k1,1) = conjg(pott(j1,2*k-2,1))
      endif
  160 continue
      do 180 k = modesy+1, nyh
      k1 = ny2 - k
      do 170 j = 1, nxh
      pot(j,k,1) = zero
      pot(j,k1,1) = zero
      pot(j,k,l1) = zero
      pot(j,k1,l1) = zero
  170 continue
  180 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 190 j = 2, jmax
      pot(j,1,1) = pott(j,1,1)
      pot(j,k1,1) = zero
      pot(j,1,l1) = zero
      pot(j,k1,l1) = zero
  190 continue
      do 200 j = jmax+1, nxh
      pot(j,1,1) = zero
      pot(j,k1,1) = zero
      pot(j,1,l1) = zero
      pot(j,k1,l1) = zero
  200 continue
      pot(1,1,1) = cmplx(real(pott(1,1,1)),0.0)
      pot(1,k1,1) = zero
      pot(1,1,l1) = zero
      pot(1,k1,l1) = zero
      if (modesx.gt.nxh) then
         pot(1,1,1) = cmplx(real(pot(1,1,1)),real(pott(j1,1,1)))
      endif
      if (modesy.gt.nyh) then
         do 210 j = 2, jmax
         pot(j,k1,1) = pott(j,ny,1)
  210    continue
         pot(1,k1,1) = cmplx(real(pott(1,ny,1)),0.0)
         if (modesx.gt.nxh) then
            pot(1,k1,1) = cmplx(real(pot(1,k1,1)),real(pott(j1,ny,1)))
         endif
      endif
c mode numbers kz = nz/2
      if (modesz.gt.nzh) then
         do 230 k = 2, kmax
         k1 = ny2 - k
         do 220 j = 2, jmax
         pot(j,k,l1) = pott(j,2*k-2,nz)
         pot(j,k1,l1) = pott(j,2*k-1,nz)
  220    continue
c mode numbers kx = 0, nx/2
         pot(1,k,l1) = pott(1,2*k-2,nz)
         if (modesx.gt.nxh) then
            pot(1,k1,l1) = conjg(pott(j1,2*k-2,nz))
         endif
  230 continue
c mode numbers ky = 0
         do 240 j = 2, jmax
         pot(j,1,l1) = pott(j,1,nz)
  240    continue
         pot(1,1,l1) = cmplx(real(pott(1,1,nz)),0.0)
         if (modesx.gt.nxh) then
            pot(1,1,l1) = cmplx(real(pot(1,1,l1)),real(pott(j1,1,nz)))
         endif
         if (modesy.gt.nyh) then
            k1 = nyh + 1
            do 250 j = 2, jmax
            pot(j,k1,l1) = pott(j,ny,nz)
  250       continue
            pot(1,k1,l1) = cmplx(real(pott(1,ny,nz)),0.0)
            if (modesx.gt.nxh) then
               pot(1,k1,l1) = cmplx(real(pot(1,k1,l1)),
     1                              real(pott(j1,ny,nz)))
            endif
         endif
      endif
      return
      end
c-----------------------------------------------------------------------
      subroutine RDVMODES3(vpot,vpott,nx,ny,nz,modesx,modesy,modesz,ndim
     1,nxvh,nyv,nzv,modesxd,modesyd,modeszd)
c this subroutine extracts lowest order modes from packed complex vector
c array vpot and stores them into a location in an unpacked complex
c vector array vpott
c modes stored: kx=(0,1,...,NX/2), ky=(0,+-1,+-2,...,+-(NY/2-1),NY/2),
c kz=(0,+-1,+-2,...,+-(NZ/2-1),NZ/2)
c nx/ny/nz = system length in x/y/z direction
c modesx/modesy/modesz = number of modes to store in x/y/z direction,
c where modesx <= nx/2+1, modesy <= ny/2+1, modesz <= nz/2+1
c ndim = number of field arrays, must be >= 1
c nxvh = second dimension of input array vpot, nxvh >= nx/2
c nyv = third dimension of input array vpot, nyv >= ny
c nzv = fourth dimension of input array vpot, nzv >= nz
c modesxd = second dimension of output array vpott, modesxd >= modesx
c modesyd = third dimension of output array vpott,
c where modesyd  >= min(2*modesy-1,ny)
c modeszd = fourth dimension of output array vpott,
c where modeszd  >= min(2*modesz-1,nz)
      implicit none
      integer nx, ny, nz, modesx, modesy, modesz, ndim, nxvh, nyv, nzv
      integer modesxd, modesyd, modeszd
      complex vpot, vpott
      dimension vpot(ndim,nxvh,nyv,nzv)
      dimension vpott(ndim,modesxd,modesyd,modeszd)
c local data
      integer nxh, nyh, nzh, lmax, kmax, jmax, ny2, nz2, i, j, k, l
      integer j1, k1, l1
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      if ((modesx.le.0).or.(modesx.gt.(nxh+1))) return
      if ((modesy.le.0).or.(modesy.gt.(nyh+1))) return
      if ((modesz.le.0).or.(modesz.gt.(nzh+1))) return
      ny2 = ny + 2
      nz2 = nz + 2
      jmax = min0(modesx,nxh)
      kmax = min0(modesy,nyh)
      lmax = min0(modesz,nzh)
      j1 = nxh + 1
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL DO PRIVATE(j,k,l,k1,l1)
      do 110 l = 2, lmax
      l1 = nz2 - l
      do 40 k = 2, kmax
      k1 = ny2 - k
      do 20 j = 2, jmax
      do 10 i = 1, ndim
      vpott(i,j,2*k-2,2*l-2) = vpot(i,j,k,l)
      vpott(i,j,2*k-1,2*l-2) = vpot(i,j,k1,l)
      vpott(i,j,2*k-2,2*l-1) = vpot(i,j,k,l1)
      vpott(i,j,2*k-1,2*l-1) = vpot(i,j,k1,l1)
   10 continue
   20 continue
c mode numbers kx = 0, nx/2
      do 30 i = 1, ndim
      vpott(i,1,2*k-2,2*l-2) = vpot(i,1,k,l)
      vpott(i,1,2*k-1,2*l-2) = conjg(vpot(i,1,k,l1))
      vpott(i,1,2*k-2,2*l-1) = vpot(i,1,k,l1)
      vpott(i,1,2*k-1,2*l-1) = conjg(vpot(i,1,k,l))
      if (modesx.gt.nxh) then
         vpott(i,j1,2*k-2,2*l-2) = conjg(vpot(i,1,k1,l1))
         vpott(i,j1,2*k-1,2*l-2) = vpot(i,1,k1,l)
         vpott(i,j1,2*k-2,2*l-1) = conjg(vpot(i,1,k1,l))
         vpott(i,j1,2*k-1,2*l-1) = vpot(i,1,k1,l1)
      endif
   30 continue
   40 continue
c mode numbers ky = 0
      do 60 j = 2, jmax
      do 50 i = 1, ndim
      vpott(i,j,1,2*l-2) = vpot(i,j,1,l)
      vpott(i,j,1,2*l-1) = vpot(i,j,1,l1)
   50 continue
   60 continue
c mode numbers kx = 0, nx/2
      do 70 i = 1, ndim
      vpott(i,1,1,2*l-2) = vpot(i,1,1,l)
      vpott(i,1,1,2*l-1) = conjg(vpot(i,1,1,l))
      if (modesx.gt.nxh) then
         vpott(i,j1,1,2*l-2) = conjg(vpot(i,1,1,l1))
         vpott(i,j1,1,2*l-1) = vpot(i,1,1,l1)
      endif
   70 continue
c mode numbers ky = ny/2
      if (modesy.gt.nyh) then
         k1 = nyh + 1
         do 90 j = 2, jmax
         do 80 i = 1, ndim
         vpott(i,j,ny,2*l-2) = vpot(i,j,k1,l)
         vpott(i,j,ny,2*l-1) = vpot(i,j,k1,l1)
   80    continue
   90    continue
         do 100 i = 1, ndim
         vpott(i,1,ny,2*l-2) = vpot(i,1,k1,l)
         vpott(i,1,ny,2*l-1) = conjg(vpot(i,1,k1,l))
         if (modesx.gt.nxh) then
            vpott(i,j1,ny,2*l-2) = conjg(vpot(i,1,k1,l1))
            vpott(i,j1,ny,2*l-1) = vpot(i,1,k1,l1)
         endif
  100    continue
      endif
  110 continue
!$OMP END PARALLEL DO
c mode numbers kz = 0
      do 150 k = 2, kmax
      k1 = ny2 - k
      do 130 j = 2, jmax
      do 120 i = 1, ndim
      vpott(i,j,2*k-2,1) = vpot(i,j,k,1)
      vpott(i,j,2*k-1,1) = vpot(i,j,k1,1)
  120 continue
  130 continue
c mode numbers kx = 0, nx/2
      do 140 i = 1, ndim
      vpott(i,1,2*k-2,1) = vpot(i,1,k,1)
      vpott(i,1,2*k-1,1) = conjg(vpot(i,1,k,1))
      if (modesx.gt.nxh) then
         vpott(i,j1,2*k-2,1) = conjg(vpot(i,1,k1,1))
         vpott(i,j1,2*k-1,1) = vpot(i,1,k1,1)
      endif
  140 continue
  150 continue
c mode numbers ky = 0
      do 170 j = 2, jmax
      do 160 i = 1, ndim
      vpott(i,j,1,1) = vpot(i,j,1,1)
  160 continue
  170 continue
      do 180 i = 1, ndim
      vpott(i,1,1,1) = cmplx(real(vpot(i,1,1,1)),0.0)
      if (modesx.gt.nxh) then
         vpott(i,j1,1,1) = cmplx(aimag(vpot(i,1,1,1)),0.0)
      endif
  180 continue
      if (modesy.gt.nyh) then
         k1 = nyh + 1
c mode numbers ky = ny/2
         do 200 j = 2, jmax
         do 190 i = 1, ndim
         vpott(i,j,ny,1) = vpot(i,j,k1,1)
  190    continue
  200    continue
         do 210 i = 1, ndim
         vpott(i,1,ny,1) = cmplx(real(vpot(i,1,k1,1)),0.0)
         if (modesx.gt.nxh) then
            vpott(i,j1,ny,1) = cmplx(aimag(vpot(i,1,k1,1)),0.0)
         endif
  210    continue
      endif
c mode numbers kz = nz/2
      if (modesz.gt.nzh) then
         l1 = nzh + 1
         do 250 k = 2, kmax
         k1 = ny2 - k
         do 230 j = 2, jmax
         do 220 i = 1, ndim
         vpott(i,j,2*k-2,nz) = vpot(i,j,k,l1)
         vpott(i,j,2*k-1,nz) = vpot(i,j,k1,l1)
  220    continue
  230    continue
c mode numbers kx = 0, nx/2
         do 240 i = 1, ndim
         vpott(i,1,2*k-2,nz) = vpot(i,1,k,l1)
         vpott(i,1,2*k-1,nz) = conjg(vpot(i,1,k,l1))
         if (modesx.gt.nxh) then
            vpott(i,j1,2*k-2,nz) = conjg(vpot(i,1,k1,l1))
            vpott(i,j1,2*k-1,nz) = vpot(i,1,k1,l1)
         endif
  240    continue
  250    continue
c mode numbers ky = 0
         do 270 j = 2, jmax
         do 260 i = 1, ndim
         vpott(i,j,1,nz) = vpot(i,j,1,l1)
  260    continue
  270    continue
         do 280 i = 1, ndim
         vpott(i,1,1,nz) = cmplx(real(vpot(i,1,1,l1)),0.0)
         if (modesx.gt.nxh) then
            vpott(i,j1,1,nz) = cmplx(aimag(vpot(i,1,1,l1)),0.0)
         endif
  280    continue
         if (modesy.gt.nyh) then
            k1 = nyh + 1
c mode numbers ky = ny/2
            do 300 j = 2, jmax
            do 290 i = 1, ndim
            vpott(i,j,ny,nz) = vpot(i,j,k1,l1)
  290       continue
  300       continue
            do 310 i = 1, ndim
            vpott(i,1,ny,nz) = cmplx(real(vpot(i,1,k1,l1)),0.0)
            if (modesx.gt.nxh) then
               vpott(i,j1,ny,nz) = cmplx(aimag(vpot(i,1,k1,l1)),0.0)
            endif
  310       continue
         endif
      endif
      return
      end
c-----------------------------------------------------------------------
      subroutine WRVMODES3(vpot,vpott,nx,ny,nz,modesx,modesy,modesz,ndim
     1,nxvh,nyv,nzv,modesxd,modesyd,modeszd)
c this subroutine extracts lowest order modes from a location in an
c unpacked complex vector array vpott and stores them into a packed
c complex vector array vpot
c modes stored: kx=(0,1,...,NX/2), ky=(0,+-1,+-2,...,+-(NY/2-1),NY/2),
c kz=(0,+-1,+-2,...,+-(NZ/2-1),NZ/2)
c nx/ny/nz = system length in x/y/z direction
c modesx/modesy/modesz = number of modes to store in x/y/z direction,
c where modesx <= nx/2+1, modesy <= ny/2+1, modesz <= nz/2+1
c ndim = number of field arrays, must be >= 1
c nxvh = second dimension of input array vpot, nxvh >= nx/2
c nyv = third dimension of input array vpot, nyv >= ny
c nzv = fourth dimension of input array vpot, nzv >= nz
c modesxd = second dimension of output array vpott, modesxd >= modesx
c modesyd = third dimension of output array vpott,
c where modesyd  >= min(2*modesy-1,ny)
c modeszd = fourth dimension of output array vpott,
c where modeszd  >= min(2*modesz-1,nz)
      implicit none
      integer nx, ny, nz, modesx, modesy, modesz, ndim, nxvh, nyv, nzv
      integer modesxd, modesyd, modeszd
      complex vpot, vpott
      dimension vpot(ndim,nxvh,nyv,nzv)
      dimension vpott(ndim,modesxd,modesyd,modeszd)
c local data
      integer nxh, nyh, nzh, lmax, kmax, jmax, ny2, nz2, i, j, k, l
      integer j1, k1, l1
      complex zero
      nxh = nx/2
      nyh = max(1,ny/2)
      nzh = max(1,nz/2)
      if ((modesx.le.0).or.(modesx.gt.(nxh+1))) return
      if ((modesy.le.0).or.(modesy.gt.(nyh+1))) return
      if ((modesz.le.0).or.(modesz.gt.(nzh+1))) return
      ny2 = ny + 2
      nz2 = nz + 2
      jmax = min0(modesx,nxh)
      kmax = min0(modesy,nyh)
      lmax = min0(modesz,nzh)
      zero = cmplx(0.0,0.0)
      j1 = nxh + 1
c mode numbers 0 < kx < nx/2, 0 < ky < ny/2, and 0 < kz < nz/2
!$OMP PARALLEL DO PRIVATE(j,k,l,k1,l1)
      do 190 l = 2, lmax
      l1 = nz2 - l
      do 60 k = 2, kmax
      k1 = ny2 - k
      do 20 j = 2, jmax
      do 10 i = 1, ndim
      vpot(i,j,k,l) = vpott(i,j,2*k-2,2*l-2)
      vpot(i,j,k1,l) = vpott(i,j,2*k-1,2*l-2)
      vpot(i,j,k,l1) = vpott(i,j,2*k-2,2*l-1)
      vpot(i,j,k1,l1) = vpott(i,j,2*k-1,2*l-1)
   10 continue
   20 continue
      do 40 j = jmax+1, nxh
      do 30 i = 1, ndim
      vpot(i,j,k,l) = zero
      vpot(i,j,k1,l) = zero
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
   30 continue
   40 continue
c mode numbers kx = 0, nx/2
      do 50 i = 1, ndim
      vpot(i,1,k,l) = vpott(i,1,2*k-2,2*l-2)
      vpot(i,1,k1,l) = zero
      vpot(i,1,k,l1) = vpott(i,1,2*k-2,2*l-1)
      vpot(i,1,k1,l1) = zero
      if (modesx.gt.nxh) then
         vpot(i,1,k1,l) = conjg(vpott(i,j1,2*k-2,2*l-1))
         vpot(i,1,k1,l1) = conjg(vpott(i,j1,2*k-2,2*l-2))
      endif
   50 continue
   60 continue
      do 90 k = kmax+1, nyh
      k1 = ny2 - k
      do 80 j = 1, nxh
      do 70 i = 1, ndim
      vpot(i,j,k,l) = zero
      vpot(i,j,k1,l) = zero
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
   70 continue
   80 continue
   90 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 110 j = 2, jmax
      do 100 i = 1, ndim
      vpot(i,j,1,l) = vpott(i,j,1,2*l-2)
      vpot(i,j,k1,l) = zero
      vpot(i,j,1,l1) = vpott(i,j,1,2*l-1)
      vpot(i,j,k1,l1) = zero
  100 continue
  110 continue
c mode numbers kx = 0, nx/2
      do 120 i = 1, ndim
      vpot(i,1,1,l) = vpott(i,1,1,2*l-2)
      vpot(i,1,k1,l) = zero
      vpot(i,1,1,l1) = zero
      vpot(i,1,k1,l1) = zero
  120 continue
      do 140 j = jmax+1, nxh
      do 130 i = 1, ndim
      vpot(i,j,1,l) = zero
      vpot(i,j,k1,l) = zero
      vpot(i,j,1,l1) = zero
      vpot(i,j,k1,l1) = zero
  130 continue
  140 continue
      do 150 i = 1, ndim
      if (modesx.gt.nxh) then
         vpot(i,1,1,l1) = conjg(vpott(i,j1,1,2*l-2))
      endif
  150 continue
c mode numbers ky = ny/2
      if (modesy.gt.nyh) then
         do 170 j = 2, jmax
         do 160 i = 1, ndim
         vpot(i,j,k1,l) = vpott(i,j,ny,2*l-2)
         vpot(i,j,k1,l1) = vpott(i,j,ny,2*l-1)
  160    continue
  170    continue
         do 180 i = 1, ndim
         vpot(i,1,k1,l) = vpott(i,1,ny,2*l-2)
         if (modesx.gt.nxh) then
            vpot(i,1,k1,l1) = conjg(vpott(i,j1,ny,2*l-2))
         endif
  180    continue
      endif
  190 continue
!$OMP END PARALLEL DO
      do 250 l = modesz+1, nzh
      l1 = nz2 - l
      do 220 k = 2, nyh
      k1 = ny2 - k
      do 210 j = 1, nxh
      do 200 i = 1, ndim
      vpot(i,j,k,l) = zero
      vpot(i,j,k1,l) = zero
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
  200 continue
  210 continue
  220 continue
      k1 = nyh + 1
      do 240 j = 1, nxh
      do 230 i = 1, ndim
      vpot(i,j,1,l) = zero
      vpot(i,j,k1,l) = zero
      vpot(i,j,1,l1) = zero
      vpot(i,j,k1,l1) = zero
  230 continue
  240 continue
  250 continue
c mode numbers kz = 0, nz/2
      l1 = nzh + 1
      do 310 k = 2, kmax
      k1 = ny2 - k
      do 270 j = 2, jmax
      do 260 i = 1, ndim
      vpot(i,j,k,1) = vpott(i,j,2*k-2,1)
      vpot(i,j,k1,1) = vpott(i,j,2*k-1,1)
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
  260 continue
  270 continue
      do 290 j = jmax+1, nxh
      do 280 i = 1, ndim
      vpot(i,j,k,1) = zero
      vpot(i,j,k1,1) = zero
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
  280 continue
  290 continue
c mode numbers kx = 0, nx/2
      do 300 i = 1, ndim
      vpot(i,1,k,1) = vpott(i,1,2*k-2,1)
      vpot(i,1,k1,1) = zero
      vpot(i,1,k,l1) = zero
      vpot(i,1,k1,l1) = zero
      if (modesx.gt.nxh) then
         vpot(i,1,k1,1) = conjg(vpott(i,j1,2*k-2,1))
      endif
  300 continue
  310 continue
      do 340 k = modesy+1, nyh
      k1 = ny2 - k
      do 330 j = 1, nxh
      do 320 i = 1, ndim
      vpot(i,j,k,1) = zero
      vpot(i,j,k1,1) = zero
      vpot(i,j,k,l1) = zero
      vpot(i,j,k1,l1) = zero
  320 continue
  330 continue
  340 continue
c mode numbers ky = 0, ny/2
      k1 = nyh + 1
      do 360 j = 2, jmax
      do 350 i = 1, ndim
      vpot(i,j,1,1) = vpott(i,j,1,1)
      vpot(i,j,k1,1) = zero
      vpot(i,j,1,l1) = zero
      vpot(i,j,k1,l1) = zero
  350 continue
  360 continue
      do 380 j = jmax+1, nxh
      do 370 i = 1, ndim
      vpot(i,j,1,1) = zero
      vpot(i,j,k1,1) = zero
      vpot(i,j,1,l1) = zero
      vpot(i,j,k1,l1) = zero
  370 continue
  380 continue
      do 390 i = 1, ndim
      vpot(i,1,1,1) = cmplx(real(vpott(i,1,1,1)),0.0)
      vpot(i,1,k1,1) = zero
      vpot(i,1,1,l1) = zero
      vpot(i,1,k1,l1) = zero
      if (modesx.gt.nxh) then
         vpot(i,1,1,1) = cmplx(real(vpot(i,1,1,1)),
     1                         real(vpott(i,j1,1,1)))
      endif
  390 continue
      if (modesy.gt.nyh) then
         do 410 j = 2, jmax
         do 400 i = 1, ndim
         vpot(i,j,k1,1) = vpott(i,j,ny,1)
  400    continue
  410    continue
         do 420 i = 1, ndim
         vpot(i,1,k1,1) = cmplx(real(vpott(i,1,ny,1)),0.0)
         if (modesx.gt.nxh) then
            vpot(i,1,k1,1) = cmplx(real(vpot(i,1,k1,1)),
     1                             real(vpott(i,j1,ny,1)))
         endif
  420    continue
      endif
c mode numbers kz = nz/2
      if (modesz.gt.nzh) then
         do 460 k = 2, kmax
         k1 = ny2 - k
         do 440 j = 2, jmax
         do 430 i = 1, ndim
         vpot(i,j,k,l1) = vpott(i,j,2*k-2,nz)
         vpot(i,j,k1,l1) = vpott(i,j,2*k-1,nz)
  430    continue
  440    continue
c mode numbers kx = 0, nx/2
         do 450 i = 1, ndim
         vpot(i,1,k,l1) = vpott(i,1,2*k-2,nz)
         if (modesx.gt.nxh) then
            vpot(i,1,k1,l1) = conjg(vpott(i,j1,2*k-2,nz))
         endif
  450    continue
  460    continue
c mode numbers ky = 0
         do 480 j = 2, jmax
         do 470 i = 1, ndim
         vpot(i,j,1,l1) = vpott(i,j,1,nz)
  470    continue
  480    continue
         do 490 i = 1, ndim
         vpot(i,1,1,l1) = cmplx(real(vpott(i,1,1,nz)),0.0)
         if (modesx.gt.nxh) then
            vpot(i,1,1,l1) = cmplx(real(vpot(i,1,1,l1)),
     1                             real(vpott(i,j1,1,nz)))
         endif
  490    continue
         if (modesy.gt.nyh) then
            k1 = nyh + 1
            do 510 j = 2, jmax
            do 500 i = 1, ndim
            vpot(i,j,k1,l1) = vpott(i,j,ny,nz)
  500       continue
  510       continue
            do 520 i = 1, ndim
            vpot(i,1,k1,l1) = cmplx(real(vpott(i,1,ny,nz)),0.0)
            if (modesx.gt.nxh) then
               vpot(i,1,k1,l1) = cmplx(real(vpot(i,1,k1,l1)),
     1                                 real(vpott(i,j1,ny,nz)))
            endif
  520       continue
         endif
      endif
      return
      end
