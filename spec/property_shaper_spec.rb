require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Shape::PropertyShaper do

  context 'Given an object with method attributes' do

    let(:source) {
      OpenStruct.new.tap do |person|
      person.name  = 'John Smith'
      person.age   = 34
      person.ssn   = 123456789
      person.children = [
        OpenStruct.new.tap do |child|
        child.name  = 'Jimmy Smith'
        end,
        OpenStruct.new.tap do |child|
        child.name  = 'Jane Smith'
        end,
      ]
      end
    }

    context 'and a Shape decorator' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :name
          property :years_of_age, from: :age
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes defined properties from source' do
          expect(subject.name).to eq('John Smith')
        end

        it 'exposes defined properties renamed from source' do
          expect(subject.years_of_age).to eq(34)
        end

        it 'does not expose unspecified attributes' do
          expect(subject).to_not respond_to(:ssn)
          expect(subject).to_not respond_to(:age)
        end
      end
    end
  end

  context 'Given a hash with attributes' do

    let(:source) do
      {
        name: 'John Smith',
        age: 34,
        ssn: 123456789,
        children: [
          {
            name: 'Jimmy Smith'
          },
          {
            name: 'Jane Smith'
          }
        ],
        spouse: {
          name: 'Sally Smith'
        }
      }
    end

    context 'and a Shape decorator' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :name
          property :years_of_age, from: :age
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes defined properties from source' do
          expect(subject.name).to eq('John Smith')
        end

        it 'exposes defined properties renamed from source' do
          expect(subject.years_of_age).to eq(34)
        end

        it 'does not expose unspecified attributes' do
          expect(subject).to_not respond_to(:ssn)
          expect(subject).to_not respond_to(:age)
        end
      end
    end

    context 'and a Shape decorator property with each_with: option' do

      before do
        stub_const('ChildDecorator', Class.new do
          include Shape::Base
          property :name
        end)
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :children, each_with: ChildDecorator
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.children.map(&:name)).to eq(['Jimmy Smith', 'Jane Smith'])
        end
      end

      context 'and a sort_by: option' do

        before do
          stub_const('MockDecorator', Class.new do
            include Shape::Base
            property :children, each_with: ChildDecorator, sort_by: :name
          end)
        end

        context 'when shaped by the decorator' do

          subject {
            MockDecorator.new(source)
          }

          it 'sorts, exposes, and shapes each child element of the property with the provided decorator' do
            expect(subject.children.map(&:name)).to eq(['Jane Smith', 'Jimmy Smith'])
          end
        end
      end
    end

    context 'and a Shape decorator property with with: option' do

      before do
        stub_const('SpouseDecorator', Class.new do
          include Shape::Base
          property :name
        end)

        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :spouse, with: SpouseDecorator
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes child element of the property with the provided decorator' do
          expect(subject.spouse.name).to eq('Sally Smith')
        end
      end
    end

    context 'and a Shape decorator property with each_with: and from: options' do

      before do
        stub_const('ChildDecorator', Class.new do
          include Shape::Base
          property :name
        end)
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :dependents, from: :children, each_with: ChildDecorator
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.dependents.map(&:name)).to eq(['Jimmy Smith', 'Jane Smith'])
        end
      end
    end

    context 'and a Shape decorator property with each_with: and from: options and a decorator defined method' do

      before do
        stub_const('ChildDecorator', Class.new do
          include Shape::Base
          property :name
        end)

        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :dependents, from: :all_children, each_with: ChildDecorator

          def all_children
            [
              OpenStruct.new.tap do |child|
              child.name  = 'Joseph Smith'
              end,
              OpenStruct.new.tap do |child|
              child.name  = 'Janet Smith'
              end
            ]
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.dependents.map(&:name)).to eq(['Joseph Smith', 'Janet Smith'])
        end
      end
    end

    context 'and a Shape decorator property using a each_with block' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :children do
            each_with do
              property :name
            end
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.children.map(&:name)).to eq(['Jimmy Smith', 'Jane Smith'])
        end
      end
    end

    context 'and a Shape decorator property using a with block' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :spouse do
            with do
              property :name
            end
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes the child element of the property with the provided decorator' do
          expect(subject.spouse.name).to eq('Sally Smith')
        end
      end
    end

    context 'and a Shape decorator property using from: option and a each_with block' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :dependents, from: :children do
            each_with do
              property :name
            end
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.dependents.map(&:name)).to eq(['Jimmy Smith', 'Jane Smith'])
        end
      end
    end

    context 'and a Shape decorator property using from: option and a with block' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :wife, from: :spouse do
            with do
              property :name
            end
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }
        it 'exposes and shapes the child element of the property with the provided decorator' do
          expect(subject.wife.name).to eq('Sally Smith')
        end
      end
    end

    context 'given nested decorated properties' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape
          property :dependents do
            property :spouse
            property :children
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes the nested properties' do
          expect(subject.to_hash[:dependents]).to eq({
            spouse: {
              name: 'Sally Smith'
            },
            children: [
              {
                name: 'Jimmy Smith'
              },
              {
                name: 'Jane Smith'
              }
            ]
          })
        end
      end
    end
  end

  context 'Given a hash with string attributes' do

    let(:source) do
      {
        'name' => 'John Smith',
        'age' => 34,
        'ssn' => 123456789,
        'children' => [
          {
            'name' => 'Jimmy Smith'
          },
          {
            'name' => 'Jane Smith'
          }
        ],
        'spouse' => {
          'name' => 'Sally Smith'
        }
      }
    end

    context 'and a Shape decorator' do

      before do
        stub_const('MockDecorator', Class.new do
          include Shape::Base
          property :name
          property :years_of_age, from: :age
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes defined properties from source' do
          expect(subject.name).to eq('John Smith')
        end

        it 'exposes defined properties renamed from source' do
          expect(subject.years_of_age).to eq(34)
        end

        it 'does not expose unspecified attributes' do
          expect(subject).to_not respond_to(:ssn)
          expect(subject).to_not respond_to(:age)
        end
      end
    end

    context 'and a Shape decorator property with with: option and a from block' do

      before do
        stub_const('ChildDecorator', Class.new do
          include Shape
          property :fullname, from: :name
        end)
        stub_const('MockDecorator', Class.new do
          include Shape
          property :first_child, with: ChildDecorator do
            from do
              _source['children'].first
            end
          end
        end)
      end

      context 'when shaped by the decorator' do

        subject {
          MockDecorator.new(source)
        }

        it 'exposes and shapes each child element of the property with the provided decorator' do
          expect(subject.first_child.fullname).to eq('Jimmy Smith')
        end

        specify do
          expect(subject.to_hash).to eq({first_child: {fullname: 'Jimmy Smith'}})
        end
      end
    end
  end
end

require 'ostruct'

RSpec.describe Shape::PropertyShaper do
  let(:context_class) do
    Class.new do
      include Shape::Base
      attr_accessor :_source
    end
  end

  let(:source) do
    OpenStruct.new(name: 'Alice', age: 42)
  end

  let(:hash_source) do
    {
      'name' => 'Bob',
      :age => 30
    }
  end

  describe 'value resolution' do
    it 'resolves value from object method' do

      context_class.class_eval do
        property :name
      end

      instance = context_class.new
      instance._source = source
      expect(instance.name).to eq('Alice')
    end

    it 'resolves value from hash using symbol key' do

      context_class.class_eval do
        property :age
      end

      instance = context_class.new
      instance._source = hash_source
      expect(instance.age).to eq(30)
    end

    it 'resolves value from hash using string key fallback' do

      context_class.class_eval do
        property :name
      end

      instance = context_class.new
      instance._source = hash_source
      expect(instance.name).to eq('Bob')
    end

    it 'returns nil when key is not found' do

      context_class.class_eval do
        property :missing
      end

      instance = context_class.new
      instance._source = hash_source
      expect(instance.missing).to be_nil
    end

    it 'resolves using custom from alias' do

      context_class.class_eval do
        property :nickname, from: :name
      end

      instance = context_class.new
      instance._source = source
      expect(instance.nickname).to eq('Alice')
    end
  end

  describe 'with and each_with' do
    before do
      stub_const('SimpleDecorator', Class.new do
        include Shape::Base
        property :name
      end)
      stub_const('ParentDecorator', Class.new do
        include Shape::Base
      end)
    end

    it 'shapes nested object with with: decorator' do

      ParentDecorator.class_eval do
        property :child, with: SimpleDecorator
      end

      instance = ParentDecorator.new({ child: { name: 'Charlie' } })
      expect(instance.child).to be_a(SimpleDecorator)
      expect(instance.child.name).to eq('Charlie')
    end

    it 'shapes collection with each_with: decorator' do

      ParentDecorator.class_eval do
        property :children, each_with: SimpleDecorator
      end

      children = [
        { name: 'Zoe' },
        { name: 'Adam' }
      ]
      instance = ParentDecorator.new({ children: children })
      expect(instance.children.map(&:name)).to contain_exactly('Zoe', 'Adam')
    end

    it 'sorts shaped collection by provided attribute' do

      ParentDecorator.class_eval do
        property :children, each_with: SimpleDecorator, sort_by: :name
      end

      unsorted = [
        { name: 'Zoe' },
        { name: 'Adam' }
      ]
      instance = ParentDecorator.new({ children: unsorted })
      expect(instance.children.map(&:name)).to eq(['Adam', 'Zoe'])
    end
  end
end

