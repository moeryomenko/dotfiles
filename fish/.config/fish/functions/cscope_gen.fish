function cscope_gen
	find -E . -regex '.*.(c|h|cc|hh|cpp|hpp|cxx|hxx|hlsl|glsl|comp|vert|frag)' > cscope.files
	cscope -b -q -k
end
