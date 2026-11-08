package com.crowndine;

import jakarta.persistence.Entity;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import static org.junit.jupiter.api.Assertions.*;

class EntityMappingTest {
    @Test void everyEntityHasACreateTableMigration() throws Exception {
        var resources = new org.springframework.core.io.support.PathMatchingResourcePatternResolver().getResources("classpath*:dev/db/migration/*.sql");
        StringBuilder ddl = new StringBuilder();
        for (var resource : resources) {
            try (var stream = resource.getInputStream()) { ddl.append(new String(stream.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8)); }
        }
        var scanner = new ClassPathScanningCandidateComponentProvider(false);
        scanner.addIncludeFilter(new AnnotationTypeFilter(Entity.class));
        for (var entity : scanner.findCandidateComponents("com.crowndine.model")) {
            var table = Class.forName(entity.getBeanClassName()).getAnnotation(jakarta.persistence.Table.class);
            if (table != null) assertTrue(java.util.regex.Pattern.compile("CREATE TABLE\\s+(?:IF NOT EXISTS\\s+)?`?" + table.name() + "`?\\s*\\(", java.util.regex.Pattern.CASE_INSENSITIVE).matcher(ddl).find(), "Missing migration: " + table.name());
        }
    }

    @Test void allEntitiesHaveValidAssociationsWithoutRequiringExternalDatabase() throws Exception {
        var registry = new StandardServiceRegistryBuilder()
                .applySetting("hibernate.dialect", "org.hibernate.dialect.MySQLDialect")
                .applySetting("hibernate.boot.allow_jdbc_metadata_access", false).build();
        try {
            var scanner = new ClassPathScanningCandidateComponentProvider(false);
            scanner.addIncludeFilter(new AnnotationTypeFilter(Entity.class));
            var sources = new MetadataSources(registry);
            var entities = scanner.findCandidateComponents("com.crowndine.model");
            assertTrue(entities.size() > 15);
            for (var entity : entities) sources.addAnnotatedClass(Class.forName(entity.getBeanClassName()));
            assertNotNull(sources.buildMetadata());
        } finally { StandardServiceRegistryBuilder.destroy(registry); }
    }
}
