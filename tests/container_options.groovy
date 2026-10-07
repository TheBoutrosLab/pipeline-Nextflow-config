import nextflow.config.ConfigParser
import nextflow.processor.TaskConfig

// Exercise Nextflow's actual task-context resolution, not a plain Map mock.
def projectDir = new File(getClass().protectionDomain.codeSource.location.path).parentFile.parentFile
def checks = 0
['docker', 'apptainer', 'singularity'].each { engine ->
    def config = new ConfigParser().setBinding([projectDir: projectDir.toPath()]).parse("""
        includeConfig "\${projectDir}/config/methods/common_methods.config"
        ${engine}.enabled = true
        methods.configure_containerization()
    """)
    def resolve = { Map directives, Map metadata ->
        def taskConfig = new TaskConfig([containerOptions: config.process.containerOptions] + directives)
        taskConfig.setContext([META: metadata])
        taskConfig.getContainerOptions().trim()
    }
    def expected = { String extra, boolean hasCpus ->
        engine == 'docker'
            ? "--cpu-shares 1024${hasCpus ? ' --cpus 3' : ''}${extra ? ' ' + extra : ''}"
            : extra
    }
    [[:], [cpus: 3]].each { cpuDirective ->
        [[:], [ext: [:]], [ext: [containerOptions: '']], [ext: [containerOptions: null]]].each { extras ->
            assert resolve(cpuDirective + extras, [:]) == expected('', !cpuDirective.isEmpty())
            checks++
        }
        assert resolve(cpuDirective + [ext: [containerOptions: '--example']], [:]) ==
            expected('--example', !cpuDirective.isEmpty())
        checks++

        def mountFlag = engine == 'docker' ? '-v' : '-B'
        def dynamicOptions = { ->
            META.containsKey('reference_fasta')
                ? "${mountFlag} \"${new File(META.reference_fasta).parent}:${new File(META.reference_fasta).parent}\""
                : ''
        }
        // Reuse the closure across tasks to catch stale or missing input bindings.
        ['/reference one/genome.fa', null, '/reference two/genome.fa'].each { reference ->
            def metadata = reference ? [reference_fasta: reference] : [:]
            def mount = reference ? "${mountFlag} \"${new File(reference).parent}:${new File(reference).parent}\"" : ''
            assert resolve(cpuDirective + [ext: [containerOptions: dynamicOptions]], metadata) ==
                expected(mount, !cpuDirective.isEmpty())
            checks++
        }
    }
}
println "SUCCESS! Container options: ${checks} checks"
