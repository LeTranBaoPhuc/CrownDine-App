package com.crowndine;

import jakarta.persistence.Entity;
import org.hibernate.boot.MetadataSources;
import org.hibernate.boot.registry.StandardServiceRegistryBuilder;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.ClassPathScanningCandidateComponentProvider;
import org.springframework.core.type.filter.AnnotationTypeFilter;
import static org.junit.jupiter.api.Assertions.*;

class EntityMappingTest {
    @Test void paymentUsesOnlyColumnsFromTheExistingSchema() throws Exception {
        var resource = new org.springframework.core.io.ClassPathResource("dev/db/migration/V1__Init.sql");
        String ddl;
        try (var stream = resource.getInputStream()) { ddl = new String(stream.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8); }
        String paymentDdl = ddl.substring(ddl.indexOf("CREATE TABLE `payments`"), ddl.indexOf("-- 18. feedbacks"));
        for (var field : com.crowndine.model.Payment.class.getDeclaredFields()) {
            var column = field.getAnnotation(jakarta.persistence.Column.class);
            if (column != null) assertTrue(paymentDdl.contains("`" + column.name() + "`"), "Payment requires a new column: " + column.name());
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
