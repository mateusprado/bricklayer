# Basic Information
Name: 		{{ name }} 	
Version: 	{{ version }}	
Release:	1%{?dist}
Summary:	{{ description }}
Group:	
License:	Internal	
URL:		{{ git_url }}

# Packager Information
Packager: Bricklayer Builder <bricklayer@locaweb.com.br>

# Build Information
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# Source Information
Source0:	
Patch0:

# Dependency Information
BuildRequires:	gcc binutils
Requires:

%description

%prep
%setup -q

%build
%configure
make %{?_smp_mflags}

%install
# make install DESTDIR=%{buildroot}
{{ install_cmd }}

%clean
rm -rf %{buildroot}

%post
/sbin/ldconfig

%postun
/sbin/ldconfig

%files
%defattr(-,root,root,-)
%doc

%changelog
* Sat Aug 29 2009 Robert Xu <robxu9@gmail.com> 7.6
- Initial Spec File
