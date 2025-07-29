require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Shape::PropertyShaper do
  let(:context_class) {
    Class.new do
      include Shape::Base
      attr_accessor :_source
    end
  }

  let(:source) {
    Struct.new(:name, :age).new('Alice', 42)
  }

  let(:hash_source) {
    {
      'name' => 'Bob',
      :age => 30
    }
  }

  context 'Given an object with method attributes' do
    let(:source) {
      OpenStruct.new(
        name: 'John Smith',
        age: 34,
        ssn: 123_456_789,
        children: [
          OpenStruct.new(name: 'Jimmy Smith'),
          OpenStruct.new(name: 'Jane Smith')
        ]
      )
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

    let(:source) {
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
              OpenStruct.new(name: 'Joseph Smith'),
              OpenStruct.new(name: 'Janet Smith')
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

    let(:source) {
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
          expect(subject.to_hash).to eq({ first_child: { fullname: 'Jimmy Smith' } })
        end
      end
    end
  end

  context 'value resolution' do
    let(:source) {
      OpenStruct.new(name: 'Alice', age: 42)
    }

    let(:hash_source) {
      { name: 'Bob', age: 30 }
    }

    let(:instance) { context_class.new }

    before do
      instance._source = current_source
    end

    context 'when resolving from object' do
      let(:current_source) { source }

      it 'resolves value from object method' do
        context_class.class_eval do
          property :name
        end

        expect(instance.name).to eq('Alice')
      end

      it 'resolves using custom from alias' do
        context_class.class_eval do
          property :nickname, from: :name
        end

        expect(instance.nickname).to eq('Alice')
      end
    end

    context 'when resolving from hash' do
      let(:current_source) { hash_source }

      it 'resolves value using symbol key' do
        context_class.class_eval do
          property :age
        end

        expect(instance.age).to eq(30)
      end

      it 'resolves value using string key fallback' do
        context_class.class_eval do
          property :name
        end

        expect(instance.name).to eq('Bob')
      end

      it 'returns nil when key is not found' do
        context_class.class_eval do
          property :missing
        end

        expect(instance.missing).to be_nil
      end
    end
  end

  context 'with and each_with' do
    let(:children) { [{ name: 'Zoe' }, { name: 'Adam' }] }
    let(:source) { { child: { name: 'Charlie' } } }
    let(:instance_one) { ParentDecorator.new(source) }
    let(:instance_two) { ParentDecorator.new(children: children) }

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

      expect(instance_one.child).to be_a(SimpleDecorator)
      expect(instance_one.child.name).to eq('Charlie')
    end

    it 'shapes collection with each_with: decorator' do
      ParentDecorator.class_eval do
        property :children, each_with: SimpleDecorator
      end

      expect(instance_two.children.map(&:name)).to contain_exactly('Zoe', 'Adam')
    end

    it 'sorts shaped collection by provided attribute' do
      ParentDecorator.class_eval do
        property :children, each_with: SimpleDecorator, sort_by: :name
      end

      expect(instance_two.children.map(&:name)).to eq(['Adam', 'Zoe'])
    end
  end
end
