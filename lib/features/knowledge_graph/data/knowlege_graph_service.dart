// ===================================================================
// Knowledge Graph Engine Implementation
// ===================================================================

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

class KnowledgeGraphService {
  static const String _neo4jEndpoint = 'https://knowledge-graph.thaiherbalgacp.com';
  final Map<String, KnowledgeNode> _localGraph = {};
  final Map<String, List<Relationship>> _relationships = {};
  late List<HerbKnowledge> _herbKnowledge;

  Future<void> initialize() async {
    await _loadHerbOntology();
    await _buildKnowledgeGraph();
    await _createSemanticRelationships();
    print('🧠 Knowledge Graph Engine initialized with ${_localGraph.length} nodes');
  }

  Future<void> _loadHerbOntology() async {
    // Load 6 herb ontology data
    _herbKnowledge = [
      // กัญชา (Cannabis)
      HerbKnowledge(
        id: 'cannabis_sativa',
        thaiName: 'กัญชา',
        scientificName: 'Cannabis sativa L.',
        family: 'Cannabaceae',
        properties: [
          HerbProperty(name: 'THC', type: 'cannabinoid', concentration: '0.2-30%'),
          HerbProperty(name: 'CBD', type: 'cannabinoid', concentration: '0.1-25%'),
          HerbProperty(name: 'Terpenes', type: 'volatile_compounds', concentration: '1-3%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'epilepsy', effectiveness: 0.85, evidence: 'clinical_trials'),
          MedicalUse(condition: 'chronic_pain', effectiveness: 0.78, evidence: 'meta_analysis'),
          MedicalUse(condition: 'chemotherapy_nausea', effectiveness: 0.82, evidence: 'rct'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['organic_soil', 'controlled_environment', 'pest_management'],
          harvestingGuidelines: ['optimal_trichome_development', 'morning_harvest', 'proper_drying'],
          storageConditions: ['temperature_controlled', 'humidity_controlled', 'light_protected'],
          qualityMarkers: ['cannabinoid_profile', 'terpene_profile', 'microbial_safety'],
        ),
        contraindications: ['pregnancy', 'lactation', 'severe_heart_disease'],
        interactions: ['warfarin', 'sedatives', 'alcohol'],
      ),
      
      // ขมิ้นชัน (Turmeric)
      HerbKnowledge(
        id: 'curcuma_longa',
        thaiName: 'ขมิ้นชัน',
        scientificName: 'Curcuma longa L.',
        family: 'Zingiberaceae',
        properties: [
          HerbProperty(name: 'Curcumin', type: 'polyphenol', concentration: '2-8%'),
          HerbProperty(name: 'Volatile oils', type: 'essential_oils', concentration: '3-7%'),
          HerbProperty(name: 'Starch', type: 'carbohydrate', concentration: '25-30%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'inflammation', effectiveness: 0.76, evidence: 'systematic_review'),
          MedicalUse(condition: 'arthritis', effectiveness: 0.68, evidence: 'clinical_trials'),
          MedicalUse(condition: 'digestive_disorders', effectiveness: 0.72, evidence: 'traditional_use'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['well_drained_soil', 'monsoon_cultivation', 'organic_fertilizer'],
          harvestingGuidelines: ['8_10_months_maturity', 'rhizome_harvest', 'clean_washing'],
          storageConditions: ['dry_storage', 'ventilated_area', 'pest_control'],
          qualityMarkers: ['curcumin_content', 'moisture_level', 'heavy_metal_testing'],
        ),
        contraindications: ['gallstones', 'bleeding_disorders', 'acid_reflux'],
        interactions: ['anticoagulants', 'diabetes_medications', 'chemotherapy'],
      ),
      
      // ขิง (Ginger)
      HerbKnowledge(
        id: 'zingiber_officinale',
        thaiName: 'ขิง',
        scientificName: 'Zingiber officinale Rosc.',
        family: 'Zingiberaceae',
        properties: [
          HerbProperty(name: 'Gingerol', type: 'phenolic_compound', concentration: '1-3%'),
          HerbProperty(name: 'Shogaol', type: 'phenolic_compound', concentration: '0.5-1%'),
          HerbProperty(name: 'Essential oils', type: 'volatile_compounds', concentration: '1-4%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'nausea', effectiveness: 0.89, evidence: 'cochrane_review'),
          MedicalUse(condition: 'motion_sickness', effectiveness: 0.82, evidence: 'rct'),
          MedicalUse(condition: 'morning_sickness', effectiveness: 0.76, evidence: 'clinical_trials'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['rich_organic_soil', 'shade_cultivation', 'regular_watering'],
          harvestingGuidelines: ['8_12_months_maturity', 'rhizome_harvest', 'immediate_processing'],
          storageConditions: ['cool_dry_place', 'good_ventilation', 'avoid_sunlight'],
          qualityMarkers: ['gingerol_content', 'essential_oil_content', 'fiber_content'],
        ),
        contraindications: ['gallstones', 'bleeding_disorders', 'high_blood_pressure'],
        interactions: ['anticoagulants', 'diabetes_medications', 'heart_medications'],
      ),
      
      // กระชายดำ (Black Galingale)
      HerbKnowledge(
        id: 'kaempferia_parviflora',
        thaiName: 'กระชายดำ',
        scientificName: 'Kaempferia parviflora Wall.',
        family: 'Zingiberaceae',
        properties: [
          HerbProperty(name: 'Methoxyflavones', type: 'flavonoids', concentration: '0.5-2%'),
          HerbProperty(name: 'Anthocyanins', type: 'polyphenols', concentration: '0.1-0.5%'),
          HerbProperty(name: 'Essential oils', type: 'volatile_compounds', concentration: '0.5-1%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'erectile_dysfunction', effectiveness: 0.71, evidence: 'clinical_trials'),
          MedicalUse(condition: 'fatigue', effectiveness: 0.68, evidence: 'pilot_studies'),
          MedicalUse(condition: 'antioxidant_support', effectiveness: 0.79, evidence: 'laboratory_studies'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['sandy_loam_soil', 'partial_shade', 'organic_matter'],
          harvestingGuidelines: ['12_18_months_maturity', 'rhizome_harvest', 'careful_handling'],
          storageConditions: ['controlled_temperature', 'low_humidity', 'dark_storage'],
          qualityMarkers: ['methoxyflavone_content', 'antioxidant_activity', 'purity_testing'],
        ),
        contraindications: ['hypotension', 'bleeding_disorders', 'pregnancy'],
        interactions: ['blood_pressure_medications', 'anticoagulants', 'sedatives'],
      ),
      
      // ไพล (Plai)
      HerbKnowledge(
        id: 'zingiber_cassumunar',
        thaiName: 'ไพล',
        scientificName: 'Zingiber cassumunar Roxb.',
        family: 'Zingiberaceae',
        properties: [
          HerbProperty(name: 'Terpinen-4-ol', type: 'monoterpene', concentration: '15-25%'),
          HerbProperty(name: 'Sabinene', type: 'monoterpene', concentration: '10-20%'),
          HerbProperty(name: 'DMPBD', type: 'phenylbutanoid', concentration: '2-5%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'muscle_pain', effectiveness: 0.81, evidence: 'clinical_trials'),
          MedicalUse(condition: 'inflammation', effectiveness: 0.74, evidence: 'in_vitro_studies'),
          MedicalUse(condition: 'sprains', effectiveness: 0.78, evidence: 'traditional_use'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['well_drained_soil', 'tropical_climate', 'organic_fertilizer'],
          harvestingGuidelines: ['10_12_months_maturity', 'rhizome_harvest', 'steam_distillation'],
          storageConditions: ['refrigerated_storage', 'sealed_containers', 'nitrogen_flushing'],
          qualityMarkers: ['essential_oil_content', 'terpinen_4_ol_content', 'antimicrobial_activity'],
        ),
        contraindications: ['skin_sensitivity', 'open_wounds', 'pregnancy'],
        interactions: ['topical_medications', 'blood_thinners', 'nsaids'],
      ),
      
      // กระท่อม (Kratom)
      HerbKnowledge(
        id: 'mitragyna_speciosa',
        thaiName: 'กระท่อม',
        scientificName: 'Mitragyna speciosa Korth.',
        family: 'Rubiaceae',
        properties: [
          HerbProperty(name: 'Mitragynine', type: 'alkaloid', concentration: '12-21%'),
          HerbProperty(name: '7-hydroxymitragynine', type: 'alkaloid', concentration: '0.01-2%'),
          HerbProperty(name: 'Paynantheine', type: 'alkaloid', concentration: '8-15%'),
        ],
        medicalUses: [
          MedicalUse(condition: 'chronic_pain', effectiveness: 0.73, evidence: 'observational_studies'),
          MedicalUse(condition: 'opioid_withdrawal', effectiveness: 0.68, evidence: 'case_reports'),
          MedicalUse(condition: 'fatigue', effectiveness: 0.65, evidence: 'user_reports'),
        ],
        gacpRequirements: GACPRequirements(
          cultivationStandards: ['tropical_rainforest', 'high_humidity', 'rich_soil'],
          harvestingGuidelines: ['mature_leaves_only', 'sustainable_harvesting', 'quick_drying'],
          storageConditions: ['airtight_containers', 'cool_dry_place', 'avoid_contamination'],
          qualityMarkers: ['alkaloid_profile', 'microbial_testing', 'heavy_metal_screening'],
        ),
        contraindications: ['pregnancy', 'lactation', 'liver_disease', 'mental_health_disorders'],
        interactions: ['opioids', 'sedatives', 'alcohol', 'psychiatric_medications'],
      ),
    ];
  }

  Future<void> _buildKnowledgeGraph() async {
    // Create nodes for each herb and their components
    for (final herb in _herbKnowledge) {
      // Main herb node
      _localGraph[herb.id] = KnowledgeNode(
        id: herb.id,
        type: NodeType.herb,
        properties: {
          'thai_name': herb.thaiName,
          'scientific_name': herb.scientificName,
          'family': herb.family,
        },
      );

      // Property nodes
      for (final property in herb.properties) {
        final propertyId = '${herb.id}_${property.name.toLowerCase()}';
        _localGraph[propertyId] = KnowledgeNode(
          id: propertyId,
          type: NodeType.property,
          properties: {
            'name': property.name,
            'type': property.type,
            'concentration': property.concentration,
          },
        );
        
        // Create CONTAINS relationship
        _addRelationship(herb.id, propertyId, RelationshipType.contains);
      }

      // Medical use nodes
      for (final use in herb.medicalUses) {
        final useId = '${herb.id}_${use.condition}';
        _localGraph[useId] = KnowledgeNode(
          id: useId,
          type: NodeType.medicalUse,
          properties: {
            'condition': use.condition,
            'effectiveness': use.effectiveness,
            'evidence': use.evidence,
          },
        );
        
        // Create TREATS relationship
        _addRelationship(herb.id, useId, RelationshipType.treats);
      }
    }
  }

  Future<void> _createSemanticRelationships() async {
    // Create relationships between herbs with similar properties
    for (int i = 0; i < _herbKnowledge.length; i++) {
      for (int j = i + 1; j < _herbKnowledge.length; j++) {
        final herb1 = _herbKnowledge[i];
        final herb2 = _herbKnowledge[j];
        
        // Check for similar medical uses
        final commonUses = herb1.medicalUses
            .where((use1) => herb2.medicalUses
                .any((use2) => use1.condition == use2.condition))
            .toList();
        
        if (commonUses.isNotEmpty) {
          _addRelationship(herb1.id, herb2.id, RelationshipType.similar);
        }
        
        // Check for same family
        if (herb1.family == herb2.family) {
          _addRelationship(herb1.id, herb2.id, RelationshipType.relatedFamily);
        }
      }
    }
  }

  void _addRelationship(String fromId, String toId, RelationshipType type) {
    if (!_relationships.containsKey(fromId)) {
      _relationships[fromId] = [];
    }
    _relationships[fromId]!.add(Relationship(
      from: fromId,
      to: toId,
      type: type,
    ));
  }

  // Semantic Query Engine
  Future<List<KnowledgeResult>> queryKnowledge(String query) async {
    final results = <KnowledgeResult>[];
    
    // Simple semantic search (in production, use vector embeddings)
    final queryLower = query.toLowerCase();
    
    for (final node in _localGraph.values) {
      double relevanceScore = 0.0;
      
      // Check node properties for matches
      for (final property in node.properties.values) {
        if (property.toString().toLowerCase().contains(queryLower)) {
          relevanceScore += 0.8;
        }
      }
      
      // Check relationships
      final relationships = _relationships[node.id] ?? [];
      for (final rel in relationships) {
        final relatedNode = _localGraph[rel.to];
        if (relatedNode != null) {
          for (final property in relatedNode.properties.values) {
            if (property.toString().toLowerCase().contains(queryLower)) {
              relevanceScore += 0.3;
            }
          }
        }
      }
      
      if (relevanceScore > 0) {
        results.add(KnowledgeResult(
          node: node,
          relevanceScore: relevanceScore,
          relationships: relationships,
        ));
      }
    }
    
    // Sort by relevance
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results.take(10).toList();
  }

  // Find related herbs
  Future<List<String>> findRelatedHerbs(String herbId) async {
    final relationships = _relationships[herbId] ?? [];
    return relationships
        .where((rel) => rel.type == RelationshipType.similar || 
                       rel.type == RelationshipType.relatedFamily)
        .map((rel) => rel.to)
        .toList();
  }

  // Get herb recommendations for condition
  Future<List<HerbRecommendation>> getRecommendationsForCondition(String condition) async {
    final recommendations = <HerbRecommendation>[];
    
    for (final herb in _herbKnowledge) {
      final relevantUses = herb.medicalUses
          .where((use) => use.condition.toLowerCase().contains(condition.toLowerCase()))
          .toList();
      
      if (relevantUses.isNotEmpty) {
        final avgEffectiveness = relevantUses
            .map((use) => use.effectiveness)
            .reduce((a, b) => a + b) / relevantUses.length;
        
        recommendations.add(HerbRecommendation(
          herbId: herb.id,
          herbName: herb.thaiName,
          effectiveness: avgEffectiveness,
          evidence: relevantUses.first.evidence,
          contraindications: herb.contraindications,
          interactions: herb.interactions,
        ));
      }
    }
    
    // Sort by effectiveness
    recommendations.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
    return recommendations;
  }

  // Knowledge Graph Analytics
  Future<KnowledgeGraphStats> getGraphStats() async {
    final herbCount = _localGraph.values.where((n) => n.type == NodeType.herb).length;
    final propertyCount = _localGraph.values.where((n) => n.type == NodeType.property).length;
    final medicalUseCount = _localGraph.values.where((n) => n.type == NodeType.medicalUse).length;
    final relationshipCount = _relationships.values.expand((list) => list).length;
    
    return KnowledgeGraphStats(
      totalNodes: _localGraph.length,
      herbNodes: herbCount,
      propertyNodes: propertyCount,
      medicalUseNodes: medicalUseCount,
      totalRelationships: relationshipCount,
      avgConnectionsPerNode: relationshipCount / _localGraph.length,
    );
  }

  Future<void> addNewKnowledge(Map<String, dynamic> data) async {
    // Implementation for continuous learning
    print('🧠 Adding new knowledge: $data');
  }
}

// Data Models
class HerbKnowledge {
  final String id;
  final String thaiName;
  final String scientificName;
  final String family;
  final List<HerbProperty> properties;
  final List<MedicalUse> medicalUses;
  final GACPRequirements gacpRequirements;
  final List<String> contraindications;
  final List<String> interactions;

  HerbKnowledge({
    required this.id,
    required this.thaiName,
    required this.scientificName,
    required this.family,
    required this.properties,
    required this.medicalUses,
    required this.gacpRequirements,
    required this.contraindications,
    required this.interactions,
  });
}

class HerbProperty {
  final String name;
  final String type;
  final String concentration;

  HerbProperty({
    required this.name,
    required this.type,
    required this.concentration,
  });
}

class MedicalUse {
  final String condition;
  final double effectiveness;
  final String evidence;

  MedicalUse({
    required this.condition,
    required this.effectiveness,
    required this.evidence,
  });
}

class GACPRequirements {
  final List<String> cultivationStandards;
  final List<String> harvestingGuidelines;
  final List<String> storageConditions;
  final List<String> qualityMarkers;

  GACPRequirements({
    required this.cultivationStandards,
    required this.harvestingGuidelines,
    required this.storageConditions,
    required this.qualityMarkers,
  });
}

class KnowledgeNode {
  final String id;
  final NodeType type;
  final Map<String, dynamic> properties;

  KnowledgeNode({
    required this.id,
    required this.type,
    required this.properties,
  });
}

enum NodeType { herb, property, medicalUse, condition, family }

class Relationship {
  final String from;
  final String to;
  final RelationshipType type;

  Relationship({
    required this.from,
    required this.to,
    required this.type,
  });
}

enum RelationshipType { contains, treats, similar, relatedFamily, contraindicated, interacts }

class KnowledgeResult {
  final KnowledgeNode node;
  final double relevanceScore;
  final List<Relationship> relationships;

  KnowledgeResult({
    required this.node,
    required this.relevanceScore,
    required this.relationships,
  });
}

class HerbRecommendation {
  final String herbId;
  final String herbName;
  final double effectiveness;
  final String evidence;
  final List<String> contraindications;
  final List<String> interactions;

  HerbRecommendation({
    required this.herbId,
    required this.herbName,
    required this.effectiveness,
    required this.evidence,
    required this.contraindications,
    required this.interactions,
  });
}

class KnowledgeGraphStats {
  final int totalNodes;
  final int herbNodes;
  final int propertyNodes;
  final int medicalUseNodes;
  final int totalRelationships;
  final double avgConnectionsPerNode;

  KnowledgeGraphStats({
    required this.totalNodes,
    required this.herbNodes,
    required this.propertyNodes,
    required this.medicalUseNodes,
    required this.totalRelationships,
    required this.avgConnectionsPerNode,
  });
}
