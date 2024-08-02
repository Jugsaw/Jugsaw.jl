JL = julia --project

default: init test

init:
	$(JL) -e 'using Pkg; libs=[Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in readdir("lib")]; Pkg.develop(libs); Pkg.instantiate(); Pkg.activate("docs"); Pkg.develop([Pkg.PackageSpec(path="."), libs...]); Pkg.instantiate()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); for pkg in readdir("lib") Pkg.activate(joinpath("lib", pkg)); Pkg.update(); end; Pkg.activate("docs"); Pkg.update()'

test:
	$(JL) -e 'using Pkg; Pkg.test()'

coverage:
	$(JL) -e 'using Pkg; Pkg.test(; coverage=true)'

serve:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); using LiveServer; servedocs(;skip_dirs=["docs/src/assets", "docs/src/generated"]) #, literate_dir="examples")'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test coverage serve clean update
