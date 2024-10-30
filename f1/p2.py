import p1
out=list()
for i in range(0,10):
	stdout=p1.luck()
	out.append(stdout)
print(out.count("good"),"/",str(len(out)))
