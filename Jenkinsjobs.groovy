pipelineJob('mariadb-docker-prod') {
    definition {
        cpsScm {
            scm {
                github('ukhc/mariadb-docker', 'master', 'https')
            }
        }
    }
}
pipelineJob('mariadb-docker-qa') {
    definition {
        cpsScm {
            scm {
                github('ukhc/mariadb-docker', 'qa', 'https')
            }
        }
    }
}