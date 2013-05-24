using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace WebIDLParser
{

    public static class TransformationConfig
    {
        public static Dictionary<string, string> renameTypePrefix =new Dictionary<string,string>();
        public static Dictionary<string, string> renameType = new Dictionary<string, string>();
        public static HashSet<string> moveToRootNamespace = new HashSet<string>();
        public static List<Tuple<string, string>> generateElementConstructor = new List<Tuple<string, string>>();
        public static Dictionary<string, string> generateElementConstructorCorrectName = new Dictionary<string, string>();
        public static Dictionary<string, string> changeDelegateResultType = new Dictionary<string, string>();
        public static Dictionary<string, List<TMethod>> addMethodToType = new Dictionary<string, List<TMethod>>();
        public static Dictionary<string, List<TProperty>> addPropertyToType = new Dictionary<string, List<TProperty>>();
    }

    public static class Transformations
    {

        public static void renameCsTypePrefix(string oldPrefix, string newPrefix)
        {
            TransformationConfig.renameTypePrefix.Add(oldPrefix, newPrefix);
        }

        public static void renameType(string oldName, string newName)
        {
            TransformationConfig.renameType.Add(oldName, newName);
        }

        public static void moveToRootNamespace(string path)
        {
            TransformationConfig.moveToRootNamespace.Add(path);
        }

        public static void generateElementConstructorForType(string typePrefix, string typePostfix)
        {
            TransformationConfig.generateElementConstructor.Add(new Tuple<string, string>(typePrefix, typePostfix));
        }

        public static void generateElementConstructorCorrectTagName(string typeName, string tagName)
        {
            TransformationConfig.generateElementConstructorCorrectName.Add(typeName, tagName);
        }

        public static void changeMemberResultType(string typeName, string membername, string newResultType)
        {
            throw new NotImplementedException();
        }

        public static void changeDelegateResultType(string delegateTypeName, string newResultType)
        {
            TransformationConfig.changeDelegateResultType.Add(delegateTypeName, newResultType);
        }

        public static void addMethodToType(string TypeName, TMethod Method)
        {
            if (TransformationConfig.addMethodToType.ContainsKey(TypeName) == false)
            {
                TransformationConfig.addMethodToType[TypeName] = new List<TMethod>();
            }
            var list = TransformationConfig.addMethodToType[TypeName];
            list.Add(Method);
        }

        public static void addPropertyToType(string TypeName, TProperty Property)
        {
            if (TransformationConfig.addPropertyToType.ContainsKey(TypeName) == false)
            {
                TransformationConfig.addPropertyToType[TypeName] = new List<TProperty>();
            }
            var list = TransformationConfig.addPropertyToType[TypeName];
            list.Add(Property);
        }

    }
        
}