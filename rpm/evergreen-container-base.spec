Name:           evergreen-container-base
Version:        %{_rpm_version}
Release:        %{_git_hash}%{?dist}
Summary:        Base container for Evergreen container builder

License:        Apache
URL:            https://github.com/10gen/%{name}


BuildRoot:      %{_tmppath}/%{name}-%{_git_hash}-build

BuildArch:      aarch64

BuildRequires:  go
BuildRequires:  jq


# Golang apps are missing a few things that gcc adds. We don't need them.
%global _missing_build_ids_terminate_build 0
%global debug_package %{nil}

%description
A base container for use with Evergreen builds that happen in
containers.


%install
install -D -m 755 /app/bom/bin/bom %{buildroot}%{_bindir}/bom
install -D -m 444 /app/bom/bom-%{_bom_version}.spdx.json.gz %{buildroot}/var/lib/db/sbom/bom-%{_bom_version}.spdx.json.gz


%files
%{_bindir}/bin
/var/lib/db/sbom/bom-%{_bom_version}.spdx.json.gz

%changelog
* Wed May 19 2023 April White <april.white@mongodb.com> - 1.0-1
- Include `bom` in the package so we can make other SBOMs
