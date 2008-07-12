require File.dirname(__FILE__) + '/../test_helper'

class EnvironmentFinderTest < ActiveSupport::TestCase

  all_fixtures

  should 'find articles' do
    person = create_user('teste').person
    art = person.articles.build(:name => 'an article to be found'); art.save!
    finder = EnvironmentFinder.new(Environment.default)
    assert_includes finder.find(:articles, 'found'), art
  end

  should 'find people' do
    p1 = create_user('people_1').person; p1.name = 'a beautiful person'; p1.save!
    finder = EnvironmentFinder.new(Environment.default)
    assert_includes finder.find(:people, 'beautiful'), p1
  end

  should 'find communities' do
    c1 = Community.create!(:name => 'a beautiful community', :identifier => 'bea_comm', :environment => Environment.default)
    finder = EnvironmentFinder.new(Environment.default)
    assert_includes finder.find(:communities, 'beautiful'), c1
  end

  should 'find products' do
    finder = EnvironmentFinder.new(Environment.default)
    ent = Enterprise.create!(:name => 'teste', :identifier => 'teste')
    prod = ent.products.create!(:name => 'a beautiful product')
    assert_includes finder.find(:products, 'beautiful'), prod
  end

  should 'find enterprises' do
    finder = EnvironmentFinder.new(Environment.default)
    ent = Enterprise.create!(:name => 'a beautiful enterprise', :identifier => 'teste')
    assert_includes finder.find(:enterprises, 'beautiful'), ent
  end

  should 'list recent enterprises' do
    finder = EnvironmentFinder.new(Environment.default)
    ent = Enterprise.create!(:name => 'teste', :identifier => 'teste')
    assert_includes finder.recent('enterprises'), ent
  end

  should 'not list more enterprises than limit' do
    finder = EnvironmentFinder.new(Environment.default)
    ent1 = Enterprise.create!(:name => 'teste1', :identifier => 'teste1')
    ent2 = Enterprise.create!(:name => 'teste2', :identifier => 'teste2')
    recent = finder.recent('enterprises', 1)
    
    assert_equal 1, recent.size
  end  
  
  should 'paginate the list of more enterprises than limit' do
    finder = EnvironmentFinder.new(Environment.default)
    ent1 = Enterprise.create!(:name => 'teste1', :identifier => 'teste1')
    ent2 = Enterprise.create!(:name => 'teste2', :identifier => 'teste2')
    
    assert_equal 1, finder.find('enterprises', nil, :per_page => 1, :page => 1).size
  end

  should 'paginate the list of more enterprises than limit with query' do
    finder = EnvironmentFinder.new(Environment.default)

    ent1 = Enterprise.create!(:name => 'teste 1', :identifier => 'teste1')
    ent2 = Enterprise.create!(:name => 'teste 2', :identifier => 'teste2')

    p1 = finder.find('enterprises', 'teste', :per_page => 1, :page => 1)
    p2 = finder.find('enterprises', 'teste', :per_page => 1, :page => 2)

    assert (p1 == [ent1] && p2 == [ent2]) || (p1 == [ent2] && p2 == [ent1])
  end
  
  should 'find person and enterprise by radius and region' do
    finder = EnvironmentFinder.new(Environment.default)
    
    region = Region.create!(:name => 'r-test', :environment => Environment.default, :lat => 45.0, :lng => 45.0)
    ent1 = Enterprise.create!(:name => 'test 1', :identifier => 'test1', :lat => 45.0, :lng => 45.0)
    p1 = create_user('test2').person
    p1.name = 'test 2'; p1.lat = 45.0; p1.lng = 45.0; p1.save!
    ent2 = Enterprise.create!(:name => 'test 3', :identifier => 'test3', :lat => 30.0, :lng => 30.0)
    p2 = create_user('test4').person
    p2.name = 'test 4'; p2.lat = 30.0; p2.lng = 30.0; p2.save!

    ents = finder.find(:enterprises, 'test', :within => 10, :region => region.id)
    people = finder.find(:people, 'test', :within => 10, :region => region.id)

    assert_includes ents, ent1
    assert_not_includes ents, ent2
    assert_includes people, p1
    assert_not_includes people, p2
  end

  should 'find person and enterprise by radius and region even without query' do
    finder = EnvironmentFinder.new(Environment.default)
    
    region = Region.create!(:name => 'r-test', :environment => Environment.default, :lat => 45.0, :lng => 45.0)
    ent1 = Enterprise.create!(:name => 'test 1', :identifier => 'test1', :lat => 45.0, :lng => 45.0)
    p1 = create_user('test2').person
    p1.name = 'test 2'; p1.lat = 45.0; p1.lng = 45.0; p1.save!
    ent2 = Enterprise.create!(:name => 'test 3', :identifier => 'test3', :lat => 30.0, :lng => 30.0)
    p2 = create_user('test4').person
    p2.name = 'test 4'; p2.lat = 30.0; p2.lng = 30.0; p2.save!

    ents = finder.find(:enterprises, nil, :within => 10, :region => region.id)
    people = finder.find(:people, nil, :within => 10, :region => region.id)

    assert_includes ents, ent1
    assert_not_includes ents, ent2
    assert_includes people, p1
    assert_not_includes people, p2
  end

  should 'find products wihin product category' do
    finder = EnvironmentFinder.new(Environment.default)
    cat = ProductCategory.create!(:name => 'test category', :environment => Environment.default)
    ent = Enterprise.create!(:name => 'test enterprise', :identifier => 'test_ent')
    prod1 = ent.products.create!(:name => 'test product 1', :product_category => cat)
    prod2 = ent.products.create!(:name => 'test product 2')    

    prods = finder.find(:products, nil, :product_category => cat)

    assert_includes prods, prod1
    assert_not_includes prods, prod2
  end

  should 'find products wihin product category with query' do
    finder = EnvironmentFinder.new(Environment.default)
    cat = ProductCategory.create!(:name => 'test category', :environment => Environment.default)
    ent = Enterprise.create!(:name => 'test enterprise', :identifier => 'test_ent')
    prod1 = ent.products.create!(:name => 'test product a_word 1', :product_category => cat)
    prod2 = ent.products.create!(:name => 'test product b_word 1', :product_category => cat)
    prod3 = ent.products.create!(:name => 'test product a_word 2')    
    prod4 = ent.products.create!(:name => 'test product b_word 2')    

    prods = finder.find(:products, 'a_word', :product_category => cat)

    assert_includes prods, prod1
    assert_not_includes prods, prod2
    assert_not_includes prods, prod3
    assert_not_includes prods, prod4
  end

  should 'find enterprises in alphabetical order of name' do
    finder = EnvironmentFinder.new(Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise B', :identifier => 'test_ent_b')
    ent2 = Enterprise.create!(:name => 'test enterprise A', :identifier => 'test_ent_a')
    ent3 = Enterprise.create!(:name => 'test enterprise C', :identifier => 'test_ent_c')

    ents = finder.find(:enterprises, nil)

    assert ents.index(ent2) < ents.index(ent1), "expected #{ents.index(ent2)} be smaller than #{ents.index(ent1)}"
    assert ents.index(ent1) < ents.index(ent3), "expected #{ents.index(ent1)} be smaller than #{ents.index(ent3)}"
  end

  should 'find enterprises by its products categories' do
    finder = EnvironmentFinder.new(Environment.default)

    pc1 = ProductCategory.create!(:name => 'test_cat1', :environment => Environment.default)
    pc2 = ProductCategory.create!(:name => 'test_cat2', :environment => Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    ent1.products.create!(:name => 'test product 1', :product_category => pc1)
    ent2 = Enterprise.create!(:name => 'test enterprise 2', :identifier => 'test_ent2')
    ent2.products.create!(:name => 'test product 2', :product_category => pc2)

    ents = finder.find(:enterprises, nil, :product_category => pc1)

    assert_includes ents, ent1
    assert_not_includes ents, ent2
  end
  
  should 'find enterprises by its products categories with query' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test_cat1', :environment => Environment.default)
    pc2 = ProductCategory.create!(:name => 'test_cat2', :environment => Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    ent1.products.create!(:name => 'test product 1', :product_category => pc1)
    ent2 = Enterprise.create!(:name => 'test enterprise 2', :identifier => 'test_ent2')
    ent2.products.create!(:name => 'test product 2', :product_category => pc2)

    ents = finder.find(:enterprises, 'test', :product_category => pc1)

    assert_includes ents, ent1
    assert_not_includes ents, ent2
  end

  should 'find enterprises by a product category with name with spaces' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test cat1', :environment => Environment.default)
    pc2 = ProductCategory.create!(:name => 'test cat2', :environment => Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    ent1.products.create!(:name => 'test product 1', :product_category => pc1)
    ent2 = Enterprise.create!(:name => 'test enterprise 2', :identifier => 'test_ent2')
    ent2.products.create!(:name => 'test product 2', :product_category => pc2)

    ents = finder.find(:enterprises, 'test', :product_category => pc1)

    assert_includes ents, ent1
    assert_not_includes ents, ent2
  end

  should 'count product categories results by products' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test cat1', :environment => Environment.default)
    pc11 = ProductCategory.create!(:name => 'test cat11', :environment => Environment.default, :parent => pc1)
    pc2 = ProductCategory.create!(:name => 'test cat2', :environment => Environment.default)
    pc3 = ProductCategory.create!(:name => 'test cat3', :environment => Environment.default)


    ent = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    p1 = ent.products.create!(:name => 'test product 1', :product_category => pc1)
    p2 = ent.products.create!(:name => 'test product 2', :product_category => pc11)
    p3 = ent.products.create!(:name => 'test product 3', :product_category => pc2)
    p4 = ent.products.create!(:name => 'test product 4', :product_category => pc2) # not in the count
    p5 = ent.products.create!(:name => 'test product 5', :product_category => pc3) # not in the count

    counts = finder.product_categories_count(:products, [pc1.id, pc11.id, pc2.id], [p1.id, p2.id, p3.id] )

    assert_equal 2, counts[pc1.id]
    assert_equal 1, counts[pc11.id]
    assert_equal 1, counts[pc2.id]
    assert_nil counts[pc3.id]
  end
  
  should 'count product categories results by all products' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test cat1', :environment => Environment.default)
    pc11 = ProductCategory.create!(:name => 'test cat11', :environment => Environment.default, :parent => pc1)
    pc2 = ProductCategory.create!(:name => 'test cat2', :environment => Environment.default)
    pc3 = ProductCategory.create!(:name => 'test cat3', :environment => Environment.default)


    ent = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    p1 = ent.products.create!(:name => 'test product 1', :product_category => pc1)
    p2 = ent.products.create!(:name => 'test product 2', :product_category => pc11)
    p3 = ent.products.create!(:name => 'test product 3', :product_category => pc2)
    p4 = ent.products.create!(:name => 'test product 4', :product_category => pc3) # not in the count

    counts = finder.product_categories_count(:products, [pc1.id, pc11.id, pc2.id] )

    assert_equal 2, counts[pc1.id]
    assert_equal 1, counts[pc11.id]
    assert_equal 1, counts[pc2.id]
    assert_nil counts[pc3.id]
  end
  
  should 'count product categories results by enterprises' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test cat1', :environment => Environment.default)
    pc11 = ProductCategory.create!(:name => 'test cat11', :environment => Environment.default, :parent => pc1)
    pc2 = ProductCategory.create!(:name => 'test cat2', :environment => Environment.default)
    pc3 = ProductCategory.create!(:name => 'test cat3', :environment => Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    ent1.products.create!(:name => 'test product 1', :product_category => pc1)
    ent1.products.create!(:name => 'test product 2', :product_category => pc1)
    ent2 = Enterprise.create!(:name => 'test enterprise 2', :identifier => 'test_ent2')
    ent2.products.create!(:name => 'test product 2', :product_category => pc11)
    ent3 = Enterprise.create!(:name => 'test enterprise 3', :identifier => 'test_ent3')
    ent3.products.create!(:name => 'test product 3', :product_category => pc2)
    ent4 = Enterprise.create!(:name => 'test enterprise 4', :identifier => 'test_ent4')
    ent4.products.create!(:name => 'test product 4', :product_category => pc2)
    ent5 = Enterprise.create!(:name => 'test enterprise 5', :identifier => 'test_ent5') # not in the count
    ent5.products.create!(:name => 'test product 5', :product_category => pc2)
    ent5.products.create!(:name => 'test product 6', :product_category => pc3)

    counts = finder.product_categories_count(:enterprises, [pc1.id, pc11.id, pc2.id], [ent1.id, ent2.id, ent3.id, ent4.id] )

    assert_equal 2, counts[pc1.id]
    assert_equal 1, counts[pc11.id]
    assert_equal 2, counts[pc2.id]
    assert_nil counts[pc3.id]
  end
  
  should 'count product categories results by all enterprises' do
    finder = EnvironmentFinder.new(Environment.default)
    
    pc1 = ProductCategory.create!(:name => 'test cat1', :environment => Environment.default)
    pc11 = ProductCategory.create!(:name => 'test cat11', :environment => Environment.default, :parent => pc1)
    pc2 = ProductCategory.create!(:name => 'test cat2', :environment => Environment.default)
    pc3 = ProductCategory.create!(:name => 'test cat3', :environment => Environment.default)

    ent1 = Enterprise.create!(:name => 'test enterprise 1', :identifier => 'test_ent1')
    ent1.products.create!(:name => 'test product 1', :product_category => pc1)
    ent1.products.create!(:name => 'test product 2', :product_category => pc1)
    ent2 = Enterprise.create!(:name => 'test enterprise 2', :identifier => 'test_ent2')
    ent2.products.create!(:name => 'test product 2', :product_category => pc11)
    ent3 = Enterprise.create!(:name => 'test enterprise 3', :identifier => 'test_ent3')
    ent3.products.create!(:name => 'test product 3', :product_category => pc2)
    ent4 = Enterprise.create!(:name => 'test enterprise 4', :identifier => 'test_ent4')
    ent4.products.create!(:name => 'test product 4', :product_category => pc2)
    ent4.products.create!(:name => 'test product 5', :product_category => pc3)

    counts = finder.product_categories_count(:enterprises, [pc1.id, pc11.id, pc2.id] )

    assert_equal 2, counts[pc1.id]
    assert_equal 1, counts[pc11.id]
    assert_equal 2, counts[pc2.id]
    assert_nil counts[pc3.id]
  end
end
