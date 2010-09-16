# Basic Information
Name: 		{{ name }} 	
Version: 	{{ version }}	
Release:	{{ release }}
Summary:	{{ description }}
Group:		Locaweb
License:	Internal	
URL:		{{ git_url }}

# Packager Information
Packager: Bricklayer Builder <bricklayer@locaweb.com.br>

# Build Information
BuildRoot:	{{ build_dir }}

# Source Information
#Source0:
#Patch0:

# Dependency Information
BuildRequires:	{{ build_packages }}
Requires: {{ required_packages }}

%description

%prep
%setup -q

%build
{{ build_cmd }}

%install
{{ install_cmd }}

%clean
rm -rf %{buildroot}

#%post
#/sbin/ldconfig

#%postun
#/sbin/ldconfig

%files
%defattr(-,root,root,-)
#%doc {{ doc_dir }}/*

%changelog
