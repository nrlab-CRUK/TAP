@Grab(group='org.codehaus.groovy', module='groovy-sql', version='3.0.10')
@Grab(group='mysql', module='mysql-connector-java', version='8.0.28')


def getExperimentType(slx)
{
    def classLoader = nextflow.Nextflow.classLoader

    def url = 'jdbc:mysql://inst-webapp.cri.camres.org:3306/wordpress?zeroDateTimeBehavior=convertToNull&characterEncoding=latin1'
    def driver = 'com.mysql.cj.jdbc.Driver'

    def type
    groovy.sql.Sql.withInstance(url, 'nrlab_reader', 'maryhadalittleiguana', driver)
    {
        gsql ->

        def query = """
            select e.DataType
            from rosenfeld_Sequence s inner join rosenfeld_Experiment e on s.aaLibraryName = e.expid
            where s.SLX_id = ${slx}
            """

        type = gsql.firstRow(query).DataType
        type = type == null ? '' : type
    }

    return type
}
