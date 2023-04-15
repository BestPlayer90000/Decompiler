local SynVersion = 'Synapse X '.._VERSION..' '..game:GetService("HttpService"):JSONDecode(syn.request({Url = 'http://httpbin.org/post', Method = 'POST', Headers = {['Content-Type'] = 'application/json'}}).Body).headers['User-Agent']
local Configs = getgenv().SynDecompilerConfigs
local SynDecompile = assert(getgenv().decompile)

getgenv().decompile = (function(Path, ...)
	if typeof(Path) == 'Instance' and Path.ClassName:find('Script') then
		local Output 

		spawn(function()
			Output = SynDecompile(Path)
		end)

		local Tick = 0

		repeat 
			task.wait(1)
			Tick = Tick + 1
		until Output or Tick == Configs.DecompilerTimeout

		if Output and Output:len() > 0 then
			Output = Output:gsub('Synapse X Luau', SynVersion)
			Output = Output:gsub('l__', '')
			Output = Output:gsub(';', '; \n')
			Output = Output:gsub('\n\nlocal', '\nlocal')
			Output = Output:gsub('\nend', 'end')
			Output = Output:gsub('\n\n	end ', '\n	end ')
			Output = Output:gsub('\n\n', '\n')

			if Configs.RemoveSemicolon then
				Output = Output:gsub(';', '')
			end

			local VariableMsg = '-- [[ Variables ]] --\n'
			local ConstantMsg = '-- [[ Constants ]] --\n'
			local DefinedConstants = {}
			local DefinedVariables = {}

			for _ = 1, Configs.GetHighestIndex(Output) do
				Output = Output:gsub('__'.._, '')
				Output = Output:gsub('u'.._, 'Constant_'.._)
				Output = Output:gsub('p'.._, 'Parameter_'.._)
				Output = Output:gsub('v'.._, 'Variable_'.._)

				if Output:find('Variable_'.._) and not Configs.IsDefined(DefinedVariables, 'local Variable_'.._) then
					Output = Output:gsub('local Variable_'.._, 'Variable_'.._)

					table.insert(DefinedVariables, 'Variable_'.._..' = nil')
				end

				if Output:find('Constant_'.._) and not Configs.IsDefined(DefinedVariables, 'local Constant_'.._) then
					Output = Output:gsub('local Constant_'.._, 'Constant_'.._)

					table.insert(DefinedConstants, 'Constant_'.._..' = nil')
				end
			end

			if #DefinedVariables > 0 then
				local Split = Output:split('-- Decompiled with the '..SynVersion..' decompiler.')[2]

				for _, DefinedVariable in pairs(DefinedVariables) do
					VariableMsg = VariableMsg..'\n'..DefinedVariable
				end

				Output = '-- Decompiled with Synapse X v3.0 | https://github.com/synllc\n\n'..VariableMsg..Split
			end

			if #DefinedConstants > 0 then
				local Split = Output:split('-- Decompiled with Synapse X v3.0 | https://github.com/synllc\n\n')[2]

				for _, DefinedVariable in pairs(DefinedConstants) do
					ConstantMsg = ConstantMsg..'\n'..DefinedVariable
				end

				Output = '-- Decompiled with Synapse X v3.0 | https://github.com/synllc\n\n'..ConstantMsg..Split
			end

			if Output:find('bytecode') then
				Output = '--'..SynVersion..'\n--No bytecode was found (most likely a Synapse X generated script or script the is empty).'
			end
		elseif Tick == Configs.DecompilerTimeout then
			Output = '--Synapse X V3 Decompilation Failed'
		end

		return Output
	else
		return '--[[ INVALID SCRIPT INSTANCE ]]--'
	end
end)