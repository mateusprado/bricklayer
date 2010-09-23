# Basic Information
Summary: {{ name }} Locaweb project
Name: {{ name }} 	
Version: {{ version }}	
Release: {{ release }}
Group: Locaweb
License: Internal	
URL: {{ git_url }}

# Dependency Information
#BuildRequires: {{ build_packages }}
#Requires: {{ required_packages }}

# Packager Information
Packager: Bricklayer Builder <bricklayer@locaweb.com.br>

# Build Information
BuildRoot: {{ build_dir }}

# Source Information
Source0: {{ source }}
#Patch0:

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
