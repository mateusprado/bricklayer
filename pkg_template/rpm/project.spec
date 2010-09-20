%define _topdir {{ top_dir }}

# Basic Information
Name: {{ name }} 	
Version: {{ version }}	
Release: {{ release }}
Summary: {{ name }} Locaweb project
Group: Locaweb
License: Internal	
URL: {{ git_url }}

# Packager Information
Packager: Bricklayer Builder <bricklayer@locaweb.com.br>

# Build Information
BuildRoot: {{ build_dir }}

# Source Information
Source0: {{ source }}
#Patch0:

# Dependency Information
#BuildRequires: {{ build_packages }}
#Requires: {{ required_packages }}

%description
{{ name }} Locaweb project

%prep
%setup -q

%build
{{ build_cmd }}

%install
{{ install_cmd }}

%clean
rm -rf %{buildroot}
rm -rf %{_builddir}/%{name}-%{version}

#%post
#/sbin/ldconfig

#%postun
#/sbin/ldconfig

%files
%defattr(-,root,root,-)
/*

%changelog
