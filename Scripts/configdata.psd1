@{

	AllNodes = @(

		@{

			NodeName = '*'

			PsDscAllowDomainUser = $true

            PsDscAllowPlainTextPassword = $true

		},

		@{

			NodeName = 'localhost'

            Role = "Primary DC"

            WindowsFeatures = 'AD-Domain-Services'

        }

    )

    NonNodeData = @{

        DomainName = 'bmoos.local'
	Domain = 'bmoos'

    }

}